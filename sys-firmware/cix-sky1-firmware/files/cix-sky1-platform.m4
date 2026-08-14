# SPDX-License-Identifier: BSD-3-Clause

include(`memory.m4')

dnl CIX's published Sky1 topologies use RAM, DMA and cache-capable buffers.
define(`PLATFORM_DAI_MEM_CAP', MEMCAPS(MEM_CAP_RAM, MEM_CAP_DMA, MEM_CAP_CACHE))
define(`PLATFORM_HOST_MEM_CAP', MEMCAPS(MEM_CAP_RAM, MEM_CAP_DMA, MEM_CAP_CACHE))
define(`PLATFORM_PASS_MEM_CAP', MEMCAPS(MEM_CAP_RAM, MEM_CAP_DMA, MEM_CAP_CACHE))
define(`PLATFORM_COMP_MEM_CAP', MEMCAPS(MEM_CAP_RAM, MEM_CAP_CACHE))

dnl Retain the 5000-MIPS scheduler token used by CIX's Sky1 pipelines.
W_VENDORTUPLES(pipe_ll_schedule_plat_tokens, sof_sched_tokens,
	LIST(`		', `SOF_TKN_SCHED_MIPS	"5000"'))
W_DATA(pipe_ll_schedule_plat, pipe_ll_schedule_plat_tokens)

W_VENDORTUPLES(pipe_media_schedule_plat_tokens, sof_sched_tokens,
	LIST(`		', `SOF_TKN_SCHED_MIPS	"5000"'))
W_DATA(pipe_media_schedule_plat, pipe_media_schedule_plat_tokens)
