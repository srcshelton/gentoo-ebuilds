# SPDX-License-Identifier: BSD-3-Clause

dnl Codec-free host playback -> volume -> host capture processing service.
include(`utils.m4')
include(`pipeline.m4')
include(`pcm.m4')
include(`common/tlv.m4')
include(`sof/tokens.m4')
include(`cix-sky1-platform.m4')

PIPELINE_PCM_ADD(sof/pipe-host-volume-playback.m4,
	4, 2, 2, s16le,
	1000, 0, 0,
	48000, 48000, 48000,
	SCHEDULE_TIME_DOMAIN_TIMER, PIPELINE_SOURCE_4)

PIPELINE_PCM_ADD(cix-sky1-host-capture.m4,
	5, 2, 2, s16le,
	1000, 0, 0,
	48000, 48000, 48000,
	SCHEDULE_TIME_DOMAIN_TIMER, NOT_USED_IGNORED)

SectionGraph."pipe-sky1-host-process" {
	index "0"
	lines [
		dapm(PIPELINE_SINK_5, PIPELINE_SOURCE_4)
	]
}

PCM_DUPLEX_ADD(HiFi5 Loopback, 2, PIPELINE_PCM_4, PIPELINE_PCM_5)
