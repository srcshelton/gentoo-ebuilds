#include <time.h>

#include <asm/hwcap.h>
#include <linux/io_uring.h>
#include <linux/netlink.h>
#include <linux/perf_event.h>
#include <linux/videodev2.h>
#include <sound/sof/tokens.h>

#ifndef EXPECTED_PERF_SIZE
#error EXPECTED_PERF_SIZE must describe the retained upstream UAPI
#endif
#ifndef EXPECT_CIX_SOF_TOKENS
#error EXPECT_CIX_SOF_TOKENS must describe the retained CIX UAPI
#endif

_Static_assert(sizeof(struct perf_event_attr) == EXPECTED_PERF_SIZE,
	       "unexpected perf_event_attr ABI");

#if EXPECT_CIX_SOF_TOKENS
#ifndef SOF_TKN_CIX_I2S_SC_RATE
#error CIX SOF topology tokens are missing
#endif
_Static_assert(SOF_TKN_CIX_I2S_SC_RATE == 2200,
	       "unexpected CIX I2SSC topology token range");
_Static_assert(SOF_TKN_CIX_I2S_MC_PIN_TX_MASK == 2308,
	       "unexpected CIX I2SMC topology token range");
#elif defined(SOF_TKN_CIX_I2S_SC_RATE)
#error unexpected CIX SOF topology tokens
#endif

int main(void)
{
	struct io_uring_params ring = { 0 };
	struct nlmsghdr netlink = { 0 };
	struct v4l2_capability video = { 0 };
	unsigned long hwcap = HWCAP_FP;

	if (ring.flags || netlink.nlmsg_flags || video.capabilities ||
	    hwcap != HWCAP_FP)
		return 1;

	return 0;
}
