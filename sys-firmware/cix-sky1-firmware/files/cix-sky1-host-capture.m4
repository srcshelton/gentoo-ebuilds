# SPDX-License-Identifier: BSD-3-Clause

dnl Host-capture endpoint for a buffer supplied by another SOF pipeline.
include(`utils.m4')
include(`pcm.m4')
include(`pipeline.m4')

W_PCM_CAPTURE(PCM_ID, Passthrough Capture, 0, DAI_PERIODS, SCHEDULE_CORE)

dnl The cross-pipeline route supplies this component's input buffer.
indir(`define', concat(`PIPELINE_SINK_', PIPELINE_ID), N_PCMC(PCM_ID))
indir(`define', concat(`PIPELINE_PCM_', PIPELINE_ID), Passthrough Capture PCM_ID)

W_PIPELINE(N_PCMC(PCM_ID), SCHEDULE_PERIOD, SCHEDULE_PRIORITY, SCHEDULE_CORE,
	SCHEDULE_TIME_DOMAIN, pipe_ll_schedule_plat)

PCM_CAPABILITIES(Passthrough Capture PCM_ID,
	CAPABILITY_FORMAT_NAME(PIPELINE_FORMAT),
	PCM_MIN_RATE, PCM_MAX_RATE,
	PIPELINE_CHANNELS, PIPELINE_CHANNELS,
	2, 16, 192, 16384, 65536, 65536)
