#!/usr/bin/env python3
"""Compile and exercise actual extracted xHCI functions, not rewritten selectors.
Usage: test-xhci-acpi-stream-quirk.py EFFECTIVE_SOURCE NEW_OUTPUT_DIR
Firmware access and unrelated xHCI lifecycle operations are mocked. No hardware.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys


def function(text, name):
    match = re.search(r'(?m)^static (?:void|int) '+name+r'\([^;]+?\n\{', text)
    if not match:
        raise ValueError('missing function '+name)
    start = match.start(); end = match.end(); depth = 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end]+'\n'


COMMON = r'''
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
typedef uint32_t u32;
typedef uint64_t u64;
#define BIT_ULL(n) (UINT64_C(1) << (n))
#define le32_to_cpu(x) (x)
#define le64_to_cpu(x) (x)
'''
SELECT = r'''
struct acpi_device { const char *hid; const char *cid; };
struct device { struct acpi_device *adev; struct device *parent; int count, error; u32 value; };
struct xhci_plat_priv { u64 quirks; };
struct xhci_hcd { u64 quirks; struct xhci_plat_priv *priv; };
#if TEST_ACPI
#define ACPI_COMPANION(d) ((d)->adev)
#else
#define ACPI_COMPANION(d) ((void)(d), (struct acpi_device *)0)
#endif
static int property_reads;
static bool acpi_dev_hid_uid_match(struct acpi_device *a, const char *hid, const char *uid)
{ assert(uid == NULL); return a && a->hid && !strcmp(a->hid, hid); }
static int device_property_count_u32(struct device *d, const char *name)
{ assert(!strcmp(name, "cdns,stream-context-quirk")); property_reads++; return d->count; }
static int device_property_read_u32(struct device *d, const char *name, u32 *v)
{ assert(!strcmp(name, "cdns,stream-context-quirk")); property_reads++; if(d->error) return d->error; *v=d->value; return 0; }
#define xhci_to_priv(x) ((x)->priv)
'''
SELECT_MAIN = r'''
static void trial(struct device d, bool enabled)
{
 struct xhci_plat_priv p={.quirks=BIT_ULL(60)};
 struct xhci_hcd x={.quirks=BIT_ULL(5),.priv=&p};
 xhci_plat_acpi_quirks(&d,&x);
 xhci_plat_quirks(&d,&x);
 assert(x.quirks == (BIT_ULL(5)|BIT_ULL(60)|((enabled && TEST_ACPI)?XHCI_CDNS_SCTX_QUIRK:0)));
}
int main(void)
{
 struct acpi_device pnp={"PNP0D10",NULL},other={"PNP0D15","PNP0D10"};
 struct device yes={.adev=&pnp,.count=1,.value=1},d=yes;
 trial(yes,true);                         /* opt-in contract, synthetic identity */
 d.count=-2;trial(d,false);                /* missing/unrelated PNP0D10 */
 d=yes;d.value=0;trial(d,false);           /* ACPI false must not count as true */
 d.value=2;trial(d,false);                 /* out-of-domain integer */
 d=yes;d.count=0;trial(d,false);           /* empty package */
 d.count=2;trial(d,false);                 /* multiple integer values */
 d.count=-22;trial(d,false);               /* string/wrong type/count error */
 d=yes;d.error=-22;trial(d,false);         /* typed read failure */
 d.error=-75;trial(d,false);               /* integer overflow */
 d=yes;d.adev=&other;property_reads=0;trial(d,false);assert(property_reads==0); /* exact HID, not CID */
 d=yes;d.adev=NULL;property_reads=0;trial(d,false);assert(property_reads==0);   /* DT / no own ACPI node */
 d=yes;d.adev=NULL;d.parent=&yes;trial(d,false); /* ACPI parent must not be inherited */
 d=yes;d.count=-2;d.parent=&yes;trial(d,false);  /* parent's property ignored */
 struct device badparent=yes;badparent.value=0;
 d=yes;d.parent=&badparent;trial(d,true);       /* child's own value wins */
 struct xhci_hcd first={0},second={0};
 d=yes;xhci_plat_acpi_quirks(&d,&first);d.value=0;xhci_plat_acpi_quirks(&d,&second);
 assert(first.quirks==(TEST_ACPI?XHCI_CDNS_SCTX_QUIRK:0));assert(second.quirks==0);
 puts("PASS: 15 selector/isolation/preservation cases");
 return 0;
}
'''
RING = r'''
#define EP_HAS_STREAMS 1
#define SET_DEQ_PENDING 2
#define COMP_SUCCESS 1
#define COMP_TRB_ERROR 5
#define COMP_CONTEXT_STATE_ERROR 19
#define COMP_SLOT_NOT_ENABLED_ERROR 11
#define TD_CLEARING_CACHE 1
#define TD_CLEARED 2
#define TR_DEQ_PTR_MASK (~UINT64_C(15))
#define TRB_TO_EP_INDEX(x) ((((x)>>16)&31)-1)
#define TRB_TO_STREAM_ID(x) ((x)>>16)
#define GET_EP_CTX_STATE(x) ((x)->state)
#define GET_SLOT_STATE(x) (x)
#define xhci_warn(...) ((void)0)
#define xhci_dbg(...) ((void)0)
#define xhci_dbg_trace(...) ((void)0)
#define trace_xhci_handle_cmd_set_deq(...) ((void)0)
#define trace_xhci_handle_cmd_set_deq_ep(...) ((void)0)
#define trace_xhci_handle_cmd_set_deq_stream(...) ((void)0)
#define list_for_each_entry_safe(pos,tmp,head,member) for((pos)=NULL,(tmp)=NULL;(pos)!=NULL;(pos)=NULL)
#define list_empty(x) (1)
struct xhci_stream_ctx { u64 stream_ring; u32 reserved[2]; };
struct xhci_ep_ctx { u64 deq; u32 state; };
struct xhci_slot_ctx { u32 dev_state; };
struct xhci_stream_info { struct xhci_stream_ctx *stream_ctx_array; };
struct xhci_virt_device { void *out_ctx; };
struct xhci_ring { void *deq_seg,*dequeue; };
struct xhci_hcd { u64 quirks; };
struct xhci_virt_ep { unsigned ep_state; struct xhci_stream_info *stream_info; struct xhci_virt_device *vdev; struct xhci_hcd *xhci; void *queued_deq_seg,*queued_deq_ptr; int cancelled_td_list; };
struct xhci_td { void *urb; int cancel_status,status; };
union xhci_trb { struct { u32 field[4]; } generic; };
static struct xhci_virt_ep ep;
static struct xhci_ring ring;
static struct xhci_ep_ctx epctx;
static struct xhci_slot_ctx slotctx;
static bool missing_ep,missing_ring;
static struct xhci_virt_ep *xhci_get_virt_ep(struct xhci_hcd *x,int slot,unsigned idx)
{ (void)x;assert(slot==1 && idx==0);return missing_ep?NULL:&ep; }
static struct xhci_ring *xhci_virt_ep_to_ring(struct xhci_hcd *x,struct xhci_virt_ep *e,unsigned id)
{ (void)x;(void)e;(void)id;return missing_ring?NULL:&ring; }
static struct xhci_ep_ctx *xhci_get_ep_ctx(struct xhci_hcd *x,void *ctx,unsigned idx)
{ (void)x;(void)ctx;(void)idx;return &epctx; }
static struct xhci_slot_ctx *xhci_get_slot_ctx(struct xhci_hcd *x,void *ctx)
{ (void)x;(void)ctx;return &slotctx; }
static u64 xhci_trb_virt_to_dma(void *seg,void *ptr) { (void)seg;(void)ptr;return 0x1000; }
static struct xhci_ring *xhci_urb_to_transfer_ring(struct xhci_hcd *x,void *urb)
{ (void)x;(void)urb;return &ring; }
#define xhci_td_cleanup(...) ((void)0)
#define xhci_invalidate_cancelled_tds(...) ((void)0)
#define ring_doorbell_for_active_rings(...) ((void)0)
#define xhci_giveback_invalidated_tds(...) ((void)0)
'''
RING_MAIN = r'''
int main(void)
{
 struct xhci_stream_ctx contexts[2];struct xhci_stream_info si={contexts};
 struct xhci_virt_device v={0};struct xhci_hcd x={0};
 union xhci_trb trb={.generic.field={0,0,1<<16,1<<16}};
 int count=0;
 for(int quirk=0;quirk<2;quirk++) for(int streams=0;streams<2;streams++)
 for(int status=0;status<5;status++) for(int missing=0;missing<3;missing++) {
  memset(contexts,0,sizeof(contexts));contexts[1].stream_ring=0x1000;
  contexts[1].reserved[0]=0x1234;contexts[1].reserved[1]=0x5678;
  x.quirks=quirk?XHCI_CDNS_SCTX_QUIRK:0;ep=(struct xhci_virt_ep){.ep_state=SET_DEQ_PENDING|(streams?EP_HAS_STREAMS:0),.stream_info=&si,.vdev=&v,.xhci=&x};
  epctx.deq=0x1000;missing_ep=missing==1;missing_ring=missing==2;
  unsigned codes[]={COMP_SUCCESS,COMP_TRB_ERROR,COMP_CONTEXT_STATE_ERROR,COMP_SLOT_NOT_ENABLED_ERROR,99};
  xhci_handle_cmd_set_deq(&x,1,&trb,codes[status]);
  bool clear=quirk && streams && status==0 && missing==0;
  assert(contexts[1].reserved[0]==(clear?0:0x1234));assert(contexts[1].reserved[1]==(clear?0:0x5678));
  if(!missing_ep) assert(!(ep.ep_state&SET_DEQ_PENDING));
  count++;
 }
 printf("PASS: %d actual Set TR Dequeue completion cases\n",count);return 0;
}
'''


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    source, out = map(Path, sys.argv[1:]); out.mkdir(parents=True, exist_ok=False)
    plat = (source/'drivers/usb/host/xhci-plat.c').read_text()
    ring = (source/'drivers/usb/host/xhci-ring.c').read_text()
    header = (source/'drivers/usb/host/xhci.h').read_text()
    define = re.search(r'(?m)^#define XHCI_CDNS_SCTX_QUIRK\s+[^\n]+', header)[0]+'\n'
    selector = function(plat, 'xhci_plat_acpi_quirks')
    existing = function(plat, 'xhci_plat_quirks')
    completion = function(ring, 'xhci_handle_cmd_set_deq')
    probe = plat[plat.index('int xhci_plat_probe('):]
    assert probe.index('xhci_plat_acpi_quirks(&pdev->dev, xhci);') < probe.index('usb_add_hcd(')
    assert 'tmpdev' not in selector and 'parent' not in selector
    dispatch = re.search(r'case TRB_SET_DEQ:.*?break;', ring, re.S)
    assert dispatch and 'xhci_handle_cmd_set_deq(' in dispatch[0]
    cases = [('selector-acpi', COMMON+define+SELECT+selector+existing+SELECT_MAIN, ['-DTEST_ACPI=1']),
             ('selector-no-acpi', COMMON+define+SELECT+selector+existing+SELECT_MAIN, ['-DTEST_ACPI=0']),
             ('stream-completion', COMMON+define+RING+completion+RING_MAIN, [])]
    compiler = os.environ.get('HOSTCC', 'cc'); receipts=[]
    for name, code, flags in cases:
        c = out/(name+'.c'); exe = out/name; c.write_text(code)
        command=[compiler, '-std=c11', '-Wall', '-Wextra', '-Werror',
                 '-Wno-unused-parameter', '-Wno-unused-but-set-variable']+flags+[str(c), '-o', str(exe)]
        r=subprocess.run(command, capture_output=True, text=True)
        (out/(name+'.compile.log')).write_text(r.stdout+r.stderr)
        if r.returncode:
            raise SystemExit(r.stderr)
        r=subprocess.run([str(exe)], capture_output=True, text=True)
        (out/(name+'.run.log')).write_text(r.stdout+r.stderr)
        if r.returncode:
            raise SystemExit(r.stderr or str(r.returncode))
        receipts.append({'name':name,'command':command,'result':r.stdout.strip(),
                         'harness_sha256':hashlib.sha256(code.encode()).hexdigest()})
        exe.unlink()
        print(name, r.stdout.strip())
    (out/'receipt.json').write_text(json.dumps({'source':str(source),'kind':'extracted actual C functions, mocked firmware/lifecycle; not ARM64 kernel/runtime qualification','functions_sha256':{n:hashlib.sha256(s.encode()).hexdigest() for n,s in [('selector',selector),('existing_quirks',existing),('stream_completion',completion)]},'results':receipts},indent=2)+'\n')


if __name__ == '__main__':
    main()
