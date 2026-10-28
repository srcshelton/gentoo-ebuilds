#!/usr/bin/env python3
"""Host regressions extracting real downstream functions (not a kernel build).

Inputs: prepared kernel tree, matching effective phy-core.c/CIX provider sources,
and an owned output directory. OS/MMIO/provider primitives are fault injected;
controller PHY helpers, generic reference accounting, mode activation, all three
role-start gates, role state machine/switch/resume and external retry are real C.
"""
import argparse
from pathlib import Path
import re
import subprocess

p = argparse.ArgumentParser(__doc__)
p.add_argument('tree', type=Path)
p.add_argument('aux', type=Path)
p.add_argument('output', type=Path)
p.add_argument('--only', choices=['all', 'ownership', 'activation'], default='all')
p.add_argument('--line', choices=['6.18', '7.2'], required=True)
a = p.parse_args()
u = a.tree / 'drivers/usb/cdns3'
a.output.mkdir(parents=True, exist_ok=True)


def fn(path, name):
    text = path.read_text()
    m = re.search(r'^(?:static )?(?:int|bool|void|enum usb_role) ' + name
                  + r'\([^;]+?\)\n\{', text, re.M)
    assert m, (path, name)
    start = text.index('{', m.start())
    end, depth = start + 1, 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[m.start():end] + '\n'


def run(name, source):
    c = a.output / (name + '.c')
    binary = a.output / name
    c.write_text(source)
    subprocess.run(['cc', '-std=gnu11', '-Wall', '-Wextra', '-Werror',
                    '-Wno-unused-parameter', '-Wno-unused-function',
                    '-fno-strict-aliasing', str(c), '-o', str(binary)], check=True)
    subprocess.run([str(binary.resolve())], check=True)


common = r'''
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#define ENOTSUPP 524
#define BIT(n) (1U << (n))
#define mutex_lock(x) ((void)(x))
#define mutex_unlock(x) ((void)(x))
#define dev_err(d, ...) ((void)(d), errors++)
#define dev_warn(d, ...) ((void)(d))
#define dev_dbg(d, ...) ((void)(d))
struct device { int id; struct device *parent; };
static int errors;
enum phy_mode { PHY_MODE_INVALID, PHY_MODE_USB_HOST, PHY_MODE_USB_DEVICE, PHY_MODE_USB_OTG };
struct phy;
struct phy_ops { int (*init)(struct phy *); int (*exit)(struct phy *);
 int (*power_on)(struct phy *); int (*power_off)(struct phy *);
 int (*set_mode)(struct phy *, enum phy_mode, int); };
struct phy { int init_count, power_count, mutex; struct device dev;
 struct phy_ops *ops; void *pwr, *data; struct { enum phy_mode mode; } attrs; };
static int phy_pm_runtime_get_sync(struct phy *p) { return 0; }
static void phy_pm_runtime_put(struct phy *p) {}
static void phy_pm_runtime_put_sync(struct phy *p) {}
static int regulator_enable(void *p) { return 0; }
static void regulator_disable(void *p) {}
'''
# Actual generic PHY counts distinguish a leaked reference from just a flag.
source = common + r'''
struct cdns { struct device *dev; struct phy *usb2_phy, *usb3_phy;
 bool usb2_phy_initialized, usb3_phy_initialized, usb2_phy_powered, usb3_phy_powered; };
static int fail_init[2], fail_exit[2], fail_on[2], fail_off[2];
static int init_calls[2], exit_calls[2], on_calls[2], off_calls[2];
static int do_init(struct phy *p) { int n=p->dev.id; init_calls[n]++; return fail_init[n]; }
static int do_exit(struct phy *p) { int n=p->dev.id; exit_calls[n]++; return fail_exit[n]; }
static int do_on(struct phy *p) { int n=p->dev.id; on_calls[n]++; return fail_on[n]; }
static int do_off(struct phy *p) { int n=p->dev.id; off_calls[n]++; return fail_off[n]; }
''' + ''.join(fn(a.aux / 'phy-core.c', 'phy_' + n)
              for n in ['init', 'exit', 'power_on', 'power_off'])
prefix = 'cdns3' if a.line == '7.2' else 'cdnsp'
platform = u / ('cdns3-plat.c' if a.line == '7.2' else 'cdnsp-plat.c')
source += ''.join(fn(platform, prefix + '_phys_' + n)
                  for n in ['init', 'exit', 'power_on', 'power_off', 'reinit'])
source += r'''
static struct phy_ops ops = { .init=do_init, .exit=do_exit, .power_on=do_on, .power_off=do_off };
static struct device dev;
static struct phy p2, p3;
static struct cdns c;
static void setup(void) {
 memset(&p2,0,sizeof(p2)); memset(&p3,0,sizeof(p3)); memset(&c,0,sizeof(c));
 memset(fail_init,0,sizeof(fail_init)); memset(fail_exit,0,sizeof(fail_exit));
 memset(fail_on,0,sizeof(fail_on)); memset(fail_off,0,sizeof(fail_off));
 memset(init_calls,0,sizeof(init_calls)); memset(exit_calls,0,sizeof(exit_calls));
 memset(on_calls,0,sizeof(on_calls)); memset(off_calls,0,sizeof(off_calls)); errors=0;
 p2.ops=p3.ops=&ops; p3.dev.id=1; c.dev=&dev; c.usb2_phy=&p2; c.usb3_phy=&p3;
}
#define phys_init PREFIX_phys_init
#define phys_exit PREFIX_phys_exit
#define phys_on PREFIX_phys_power_on
#define phys_off PREFIX_phys_power_off
#define phys_reinit PREFIX_phys_reinit
int main(void) {
 int cases=0;
 setup(); fail_init[1]=-EIO; fail_exit[0]=-EBUSY;
 assert(phys_init(&c)==-EIO && c.usb2_phy_initialized && p2.init_count==1);
 for (int i=0;i<3;i++) assert(phys_init(&c)==-EIO && p2.init_count==1);
 assert(init_calls[0]==1);
 if (WITH_UNWIND) assert(exit_calls[0]==1 && errors==6); cases++;
 fail_exit[0]=0; assert(phys_exit(&c)==0 && !c.usb2_phy_initialized && p2.init_count==0); cases++;
 fail_init[1]=0; assert(!phys_init(&c) && !phys_init(&c));
 assert(p2.init_count==1 && p3.init_count==1); assert(!phys_exit(&c)); cases++;
 setup(); assert(!phys_init(&c)); fail_on[1]=-EIO; fail_off[0]=-EBUSY;
 assert(phys_on(&c)==-EIO && c.usb2_phy_powered && p2.power_count==1);
 for (int i=0;i<3;i++) assert(phys_on(&c)==-EIO && p2.power_count==1);
 assert(on_calls[0]==1);
 if (WITH_UNWIND) assert(off_calls[0]==1 && errors==6); cases++;
 fail_off[0]=0; assert(!phys_off(&c) && !c.usb2_phy_powered && p2.power_count==0); cases++;
 fail_on[1]=0; assert(!phys_on(&c) && !phys_on(&c));
 assert(p2.power_count==1 && p3.power_count==1); assert(!phys_off(&c) && !phys_exit(&c)); cases++;
 /* Pre-existing USB2 ownership belongs to the caller, not this invocation. */
 setup(); p2.init_count=1; c.usb2_phy_initialized=true; fail_init[1]=-EIO;
 assert(phys_init(&c)==-EIO && p2.init_count==1 && exit_calls[0]==0 && init_calls[0]==0); cases++;
 setup(); p2.power_count=1; c.usb2_phy_powered=true; fail_on[1]=-EIO;
 assert(phys_on(&c)==-EIO && p2.power_count==1 && off_calls[0]==0 && on_calls[0]==0); cases++;
 /* Pre-existing USB3 is never duplicated when USB2 is newly acquired. */
 setup(); p3.init_count=1; c.usb3_phy_initialized=true; assert(!phys_init(&c));
 assert(p2.init_count==1 && p3.init_count==1 && init_calls[1]==0); assert(!phys_exit(&c)); cases++;
 setup(); p3.power_count=1; c.usb3_phy_powered=true; assert(!phys_on(&c));
 assert(p2.power_count==1 && p3.power_count==1 && on_calls[1]==0); assert(!phys_off(&c)); cases++;
 setup(); assert(!phys_init(&c)); fail_exit[1]=-EIO;
 assert(phys_reinit(&c)==-EIO && c.usb3_phy_initialized && !c.usb2_phy_initialized);
 assert(p2.init_count==0 && p3.init_count==1); fail_exit[1]=0;
 assert(!phys_reinit(&c) && p2.init_count==1 && p3.init_count==1); assert(!phys_exit(&c)); cases++;
 setup(); c.usb2_phy=NULL; fail_init[1]=-EIO; assert(phys_init(&c)==-EIO); assert(!phys_exit(&c)); cases++;
 setup(); c.usb2_phy=NULL; fail_on[1]=-EIO; assert(phys_on(&c)==-EIO); assert(!phys_off(&c)); cases++;
 printf("PASS: %d actual-helper/generic-PHY ownership scenarios\n",cases);
}
'''.replace('PREFIX', prefix).replace('WITH_UNWIND', '1' if a.line == '7.2' else '0')
if a.only != 'activation':
    run('ownership', source)

# Real mode callbacks, activation functions, role bookkeeping and resume.
h = (u / 'drd.h').read_text()
structs = ''
for name in ['cdns3_otg_regs', 'cdns3_otg_legacy_regs', 'cdnsp_otg_regs', 'cdns_otg_common_regs']:
    start = h.index('struct ' + name + ' {')
    structs += h[start:h.index('};', start) + 2] + '\n'
source = common + r'''
typedef uint32_t u32;
typedef uint32_t __le32;
#define WARN_ON(x) (x)
#define CDNS3_CONTROLLER_V0 0
#define CDNS3_CONTROLLER_V1 1
#define CDNSP_CONTROLLER_V2 2
#define CDNS_ROLE_STATE_INACTIVE 0
#define CDNS_ROLE_STATE_ACTIVE 1
#define USB_DR_MODE_OTG 0
#define USB_DR_MODE_HOST 1
#define USB_DR_MODE_PERIPHERAL 2
#define OTGCMD_HOST_BUS_REQ BIT(1)
#define OTGCMD_DEV_BUS_REQ BIT(0)
#define OTGCMD_OTG_DIS BIT(3)
#define OTGCMD_HOST_BUS_DROP BIT(9)
#define OTGCMD_DEV_BUS_DROP BIT(8)
#define OTGCMD_DEV_POWER_OFF BIT(11)
#define OTGCMD_HOST_POWER_OFF BIT(12)
#define OTGSTS_CDNSP_XHCI_READY BIT(27)
#define OTGSTS_CDNS3_XHCI_READY BIT(26)
#define OTGSTS_CDNSP_DEV_READY BIT(26)
#define OTGSTS_CDNS3_DEV_READY BIT(27)
#define OTGSTATE_HOST_STATE_MASK 7
#define OTGSTATE_DEV_STATE_MASK (7 << 3)
#define UDPHY_MODE_NONE 0
#define UDPHY_MODE_USB 1
#define UDPHY_MODE_DP 2
#define UDPHY_MODE_DP_USB 3
#define usleep_range(a,b) ((void)0)
struct cdns;
enum usb_role { USB_ROLE_NONE, USB_ROLE_HOST, USB_ROLE_DEVICE };
struct role_driver { int state; int (*start)(struct cdns *);
 void (*stop)(struct cdns *); int (*resume)(struct cdns *, bool); };
struct platform_device { struct device dev; };
struct xhci_plat_priv { unsigned long quirks; };
struct pdata { unsigned long quirks; };
struct cdns { struct device *dev; struct phy *usb2_phy, *usb3_phy;
 int mutex, version, dr_mode; enum usb_role role; void *role_sw; bool no_drd;
 struct role_driver *roles[3]; struct cdns3_otg_legacy_regs *otg_v0_regs;
 struct cdns3_otg_regs *otg_v1_regs; struct cdnsp_otg_regs *otg_cdnsp_regs;
 struct cdns_otg_common_regs *otg_regs; struct platform_device *host_dev;
 struct xhci_plat_priv *xhci_plat_data; struct pdata *pdata;
 void *xhci_regs, *gadget_dev, *dev_regs; int xhci_res[2], dev_irq; };
struct usb_role_switch { struct cdns *data; };
static struct cdns *usb_role_switch_get_drvdata(struct usb_role_switch *s) { return s->data; }
static int pm_refs, allocs, poll_fail, stops, resumes, target_error, fallback_error;
static int pm_runtime_get_sync(struct device *d) { pm_refs++; return 0; }
static void pm_runtime_put_sync(struct device *d) { pm_refs--; }
static bool id_pin, vbus_pin;
static int cdns_get_id(struct cdns *c) { return id_pin; }
static int cdns_get_vbus(struct cdns *c) { return vbus_pin; }
static bool cdns_is_host(struct cdns *c) { return c->dr_mode==USB_DR_MODE_HOST; }
static bool cdns_is_device(struct cdns *c) { return c->dr_mode==USB_DR_MODE_PERIPHERAL; }
static u32 readl(u32 *p) { return *p; }
static void writel(u32 v, u32 *p) { *p=v; }
#define readl_poll_timeout_atomic(p,v,c,d,t) ((v)=readl(p), (void)(c), poll_fail ? -ETIMEDOUT : 0)
struct cix_udphy;
struct cix_udphy_cfg { int (*udphy_init)(struct cix_udphy *); int (*udphy_exit)(struct cix_udphy *); };
struct cix_udphy { int mutex, cur_mode, next_mode, phy_init_skip_count; void *apb_clk;
 const struct cix_udphy_cfg *cfg; };
static int hw_error, hw_exit_error, hw_count, hw_inits, hw_exits;
static int hw_init(struct cix_udphy *u) { hw_inits++; if (hw_error) return hw_error; hw_count++; return 0; }
static int hw_exit(struct cix_udphy *u) { hw_exits++; hw_count--; return hw_exit_error; }
static int sky1_udphy_clk_enable(void *c) { return hw_error; }
static void *phy_get_drvdata(struct phy *p) { return p->data; }
''' + structs
source += ''.join(fn(a.aux / 'phy-cix-usbdp.c', n) for n in [
    'cix_usbdp_phy_power_on', 'cix_usbdp_phy_power_off', 'cix_u3phy_init',
    'cix_u3phy_exit', 'cix_u3phy_set_mode'])
source += fn(a.aux / 'phy-core.c', 'phy_set_mode_ext') + r'''
#define phy_set_mode(p,m) phy_set_mode_ext(p,m,0)
static int usb2_error, usb2_clear_error, usb2_active, clears[2];
static int usb2_mode(struct phy *p, enum phy_mode mode, int sub) {
 if (mode==PHY_MODE_INVALID) { clears[0]++; if (usb2_clear_error) return usb2_clear_error; usb2_active=0; return 0; }
 usb2_active=1; return usb2_error; /* Failure deliberately has a partial side effect. */
}
static int usb3_mode(struct phy *p, enum phy_mode mode, int sub) {
 if (mode==PHY_MODE_INVALID) clears[1]++;
 return cix_u3phy_set_mode(p,mode,sub);
}
void cdns_drd_host_off(struct cdns *c);
void cdns_drd_gadget_off(struct cdns *c);
'''
source += ''.join(fn(u / 'drd.c', n) for n in ['cdns_drd_host_on', 'cdns_drd_host_off',
                                             'cdns_drd_gadget_on', 'cdns_drd_gadget_off'])
# Compile the complete three role-start callers, including their post-gate bodies.
source += r'''
#define kzalloc_obj(obj) kzalloc(sizeof(obj),0)
#define GFP_KERNEL 0
#define PLATFORM_DEVID_AUTO 0
#define CDNS_XHCI_RESOURCES_NUM 2
#define CDNS3_DEFAULT_PM_RUNTIME_ALLOW 1
#define XHCI_DEFAULT_PM_RUNTIME_ALLOW 1
#define DMA_BIT_MASK(x) UINT64_MAX
#define CDNSP_EP0_SETUP_SIZE 8
#define IRQF_SHARED 1
#define fallthrough ((void)0)
#define USB_SPEED_UNKNOWN 0
#define USB_SPEED_FULL 1
#define USB_SPEED_HIGH 2
#define USB_SPEED_SUPER 3
#define USB_SPEED_SUPER_PLUS 4
struct gadget { const void *ops; const char *name; int speed, sg_supported, max_speed, lpm_capable, quirk_ep_out_aligned_size; };
struct cdnsp_device { struct device *dev; void *regs, *setup_buf; struct gadget gadget; };
struct usb_hcd { void *regs; };
static const struct xhci_plat_priv xhci_plat_cdns3_xhci, xhci_plat_cdnsp_xhci;
static const int cdnsp_gadget_ops;
static const char *dev_name(struct device *d) { return "test"; }
static void *kzalloc(size_t n,int g) { allocs++; return calloc(1,n); }
static void *kmemdup(const void *p,size_t n,int g) { allocs++; void *v=malloc(n); memcpy(v,p,n); return v; }
static void kfree(void *p) { free(p); }
static struct platform_device *platform_device_alloc(const char *n,int id) { allocs++; return calloc(1,sizeof(struct platform_device)); }
static int platform_device_add_resources(struct platform_device *p,void *r,int n) { return 0; }
static int platform_device_add_data(struct platform_device *p,void *r,int n) { return 0; }
static int platform_device_add(struct platform_device *p) { return 0; }
static void platform_device_put(struct platform_device *p) { free(p); }
static struct usb_hcd *platform_get_drvdata(struct platform_device *p) { static struct usb_hcd h; return &h; }
static int usb_get_maximum_speed(struct device *d) { return USB_SPEED_SUPER_PLUS; }
static int cdnsp_gen_setup(struct cdnsp_device *p) { return 0; }
static int cdnsp_gadget_init_endpoints(struct cdnsp_device *p) { return 0; }
static int usb_add_gadget_udc(struct device *d,struct gadget *g) { return 0; }
static void cdnsp_irq_handler(void) {}
static void cdnsp_thread_irq_handler(void) {}
static void cdns3_device_irq_handler(void) {}
static void cdns3_device_thread_irq_handler(void) {}
static int devm_request_threaded_irq(struct device *d,int i,void(*a)(void),void(*b)(void),int f,const char*n,void*p) { return 0; }
static void usb_del_gadget(struct gadget *g) {}
static void usb_put_gadget(struct gadget *g) {}
static void cdnsp_gadget_free_endpoints(struct cdnsp_device *p) {}
static void cdnsp_halt(struct cdnsp_device *p) {}
static int cdnsp_reset(struct cdnsp_device *p) { return 0; }
static void cdnsp_mem_cleanup(struct cdnsp_device *p) {}
static int dma_set_mask_and_coherent(struct device *d,uint64_t mask) { return 0; }
static int cdns3_gadget_start(struct cdns *c) { return 0; }
static void cdns3_gadget_exit(struct cdns *c) {}
'''
source += fn(u / 'host.c', '__cdns_host_init')
source += fn(u / 'cdnsp-gadget.c', '__cdnsp_gadget_init')
source += fn(u / 'cdns3-gadget.c', '__cdns3_gadget_init')
source += ''.join(fn(u / 'core.c', n) for n in ['cdns_role_start', 'cdns_role_stop',
    'cdns_hw_role_state_machine', 'cdns_hw_role_switch', 'cdns_role_set'])
source += fn(u / 'drd.c', 'cdns_power_is_lost') + fn(u / 'core.c', 'cdns_resume')
source += r'''
static struct device dev;
static struct cdns c;
static struct phy p2,p3;
static struct cix_udphy ud;
static struct cdnsp_otg_regs regs;
static struct role_driver roles[3];
static struct phy_ops ops2={.set_mode=usb2_mode}, ops3={.set_mode=usb3_mode};
static const struct cix_udphy_cfg cfg={.udphy_init=hw_init,.udphy_exit=hw_exit};
static int role_start(struct cdns *x) {
 if (x->role==USB_ROLE_NONE) return fallback_error;
 if (target_error) return target_error;
 return x->role==USB_ROLE_HOST ? cdns_drd_host_on(x) : cdns_drd_gadget_on(x);
}
static void role_stop(struct cdns *x) { stops++; }
static int role_resume(struct cdns *x,bool lost) { resumes++; return 0; }
static void setup(void) {
 memset(&c,0,sizeof(c)); memset(&p2,0,sizeof(p2)); memset(&p3,0,sizeof(p3));
 memset(&ud,0,sizeof(ud)); memset(&regs,0,sizeof(regs)); memset(roles,0,sizeof(roles));
 errors=pm_refs=allocs=poll_fail=stops=resumes=target_error=fallback_error=0;
 usb2_error=usb2_clear_error=usb2_active=hw_error=hw_exit_error=hw_count=hw_inits=hw_exits=0;
 clears[0]=clears[1]=0; id_pin=false; vbus_pin=true;
 c.dev=&dev; c.usb2_phy=&p2; c.usb3_phy=&p3; p2.ops=&ops2; p3.ops=&ops3; p3.data=&ud;
 ud.next_mode=UDPHY_MODE_USB; ud.cfg=&cfg; c.version=CDNSP_CONTROLLER_V2;
 c.otg_cdnsp_regs=&regs; c.otg_regs=(void*)&regs.cmd;
 regs.sts=UINT32_MAX; c.dr_mode=USB_DR_MODE_OTG;
 for(int i=0;i<3;i++) { roles[i].start=role_start; roles[i].stop=role_stop; roles[i].resume=role_resume; c.roles[i]=&roles[i]; }
 c.role=USB_ROLE_NONE; roles[0].state=CDNS_ROLE_STATE_ACTIVE;
}
int main(void) {
 int cases=0;
 for(int device=0;device<2;device++) for(int fail=0;fail<2;fail++) {
  setup(); if(fail) hw_error=-EIO; else usb2_error=-EIO;
  int r=device ? cdns_drd_gadget_on(&c) : cdns_drd_host_on(&c);
  assert(r==-EIO && !usb2_active && !ud.cur_mode && !hw_count);
  assert(clears[0]==1 && clears[1]==1); cases++;
  usb2_error=hw_error=0;
  assert(!(device ? cdns_drd_gadget_on(&c) : cdns_drd_host_on(&c)));
  assert(hw_count==1 && ud.cur_mode==UDPHY_MODE_USB);
  /* Reasserting a mode cannot take a duplicate provider clock reference. */
  assert(!(device ? cdns_drd_gadget_on(&c) : cdns_drd_host_on(&c)) && hw_count==1);
  if(device) cdns_drd_gadget_off(&c); else cdns_drd_host_off(&c);
  assert(!hw_count && !usb2_active); cases++;
 }
 setup(); hw_error=-EIO; usb2_clear_error=-EBUSY;
 assert(cdns_drd_host_on(&c)==-EIO && errors==1 && clears[1]==1); cases++;
 setup(); ud.cur_mode=UDPHY_MODE_DP; ud.next_mode=UDPHY_MODE_DP_USB;
 assert(cdns_drd_host_on(&c)==-EBUSY && ud.cur_mode==UDPHY_MODE_DP && hw_exits==0); cases++;
 setup(); assert(!cdns_drd_host_on(&c)); hw_exit_error=-EIO; cdns_drd_host_off(&c);
 assert(errors==1 && !hw_count && !ud.cur_mode); hw_exit_error=0;
 assert(!cdns_drd_host_on(&c) && hw_count==1); cdns_drd_host_off(&c); cases++;
 setup(); poll_fail=1; assert(cdns_drd_host_on(&c)==-ETIMEDOUT && hw_inits==0); cases++;
 setup(); poll_fail=1; assert(cdns_drd_gadget_on(&c)==-ETIMEDOUT && hw_inits==0); cases++;
 /* All three real role-start functions return before allocation/PM on mode error. */
 int (*starts[])(struct cdns*)={__cdns_host_init,__cdnsp_gadget_init,__cdns3_gadget_init};
 for(int i=0;i<3;i++) for(int fail=0;fail<2;fail++) { setup(); if(fail) hw_error=-EIO; else usb2_error=-EIO;
  assert(starts[i](&c)==-EIO && !allocs && !pm_refs && !c.host_dev && !c.gadget_dev); cases++; }
 /* Registration can precede role-driver initialization. Preserve its no-op. */
 setup(); c.roles[USB_ROLE_NONE]=NULL; struct usb_role_switch early={.data=&c};
 assert(!cdns_role_set(&early,USB_ROLE_NONE) && !stops && !pm_refs); cases++;
 /* Actual external role setter must retry an inactive unchanged role. */
 for(int device=0;device<2;device++) { setup(); hw_error=-EIO;
  struct usb_role_switch sw={.data=&c}; enum usb_role role=device ? USB_ROLE_DEVICE : USB_ROLE_HOST;
  assert(cdns_role_set(&sw,role)==-EIO && roles[role].state==CDNS_ROLE_STATE_INACTIVE && stops==1);
  hw_error=0; assert(!cdns_role_set(&sw,role) && roles[role].state==CDNS_ROLE_STATE_ACTIVE && hw_count==1 && stops==1);
  assert(!cdns_role_set(&sw,role) && hw_count==1 && stops==1); cases++; }
 /* Actual hardware switch: requested start fails; idle fallback succeeds. */
 setup(); target_error=-EIO;
 assert(!cdns_resume(&c) && c.role==USB_ROLE_NONE && roles[0].state==CDNS_ROLE_STATE_ACTIVE);
 assert(roles[1].state==CDNS_ROLE_STATE_INACTIVE && regs.simulate==1 && !resumes && !pm_refs); cases++;
 /* Fallback failure is returned and does not re-arm; a later retry can start. */
 setup(); target_error=-EIO; fallback_error=-ENOMEM;
 assert(cdns_resume(&c)==-ENOMEM && c.role==USB_ROLE_NONE && roles[0].state==CDNS_ROLE_STATE_INACTIVE && !regs.simulate);
 target_error=fallback_error=0; assert(!cdns_resume(&c) && c.role==USB_ROLE_HOST && roles[1].state==CDNS_ROLE_STATE_ACTIVE && regs.simulate==1); cases++;
 /* Existing-role lost-context mode failure reaches resume and retains marker. */
 for(int device=0;device<2;device++) { setup(); c.role=device ? USB_ROLE_DEVICE : USB_ROLE_HOST;
  c.role_sw=&c; roles[c.role].state=CDNS_ROLE_STATE_ACTIVE; hw_error=-EIO;
  assert(cdns_resume(&c)==-EIO && !regs.simulate && !resumes);
  hw_error=0; assert(!cdns_resume(&c) && regs.simulate==1 && resumes==1); cases++; }
''' + (r'''
 setup(); c.no_drd=true; c.otg_regs=NULL; c.otg_cdnsp_regs=NULL; hw_error=-EIO;
 assert(!cdns_power_is_lost(&c)); assert(cdns_drd_host_on(&c)==-EIO); cases++;
''' if a.line == '7.2' else '') + r'''
 printf("PASS: %d actual-activation/provider/role contract scenarios\n",cases);
}
'''
if a.only != 'ownership':
    run('activation', source)
