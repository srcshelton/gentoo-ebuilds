# SPDX-License-Identifier: GPL-2.0-or-later

BEGIN {
	quote = sprintf("%c", 39)
}

function pipeline_id(name) {
	if (name == "PCM0P" || name == "BUF1.0" ||
	    name == "I2SMC3.OUT" || name == "PIPELINE.1.I2SMC3.OUT")
		return 1
	if (name == "PCM1P" || name == "BUF2.0" ||
	    name == "I2SSC0.OUT" || name == "PIPELINE.2.I2SSC0.OUT")
		return 2
	if (name == "PCM1C" || name == "BUF3.0" ||
	    name == "I2SSC0.IN" || name == "PIPELINE.3.I2SSC0.IN")
		return 3
	return 0
}

function print_backend(name, id) {
	print "\t" name " {"
	print "\t\tid " id
	print "\t\tdefault_hw_conf_id " id
	print "\t\thw_configs ["
	print "\t\t\t" quote name quote
	print "\t\t]"
	print "\t\tdata " quote name ":tuple0" quote
	print "\t}"
}

function print_hw_config(name, id) {
	print "SectionHWConfig." quote name quote " {"
	print "\tid " id
	print "\tformat " quote "I2S" quote
	print "\tbclk " quote "codec_consumer" quote
	print "\tfsync " quote "codec_consumer" quote
	print "\tpm_gate_clocks true"
	print "}"
}

/^SectionWidget \{$/ {
	in_widgets = 1
	next
}

in_widgets && /^\t/ && $2 == "{" {
	name = substr($1, 2, length($1) - 2)
	widget_index = pipeline_id(name)
	if (!widget_index) {
		print "unknown CIX SOF widget: " name > "/dev/stderr"
		exit 1
	}
	print "SectionWidget." quote name quote " {"
	print "\tindex " quote widget_index quote
	widgets++
	next
}

in_widgets && /^\t}$/ {
	print "}"
	next
}

in_widgets && /^}$/ {
	in_widgets = 0
	next
}

in_widgets {
	sub(/^\t/, "")
	print
	next
}

/^SectionBE \{$/ {
	in_backends = 1
	print_hw_config("NoCodec-3", 3)
	print_hw_config("NoCodec-0", 0)
	print
	next
}

in_backends && /^\tNoCodec-3\.data / {
	print_backend("NoCodec-3", 3)
	backends++
	next
}

in_backends && /^\tNoCodec-0\.data / {
	print_backend("NoCodec-0", 0)
	backends++
	next
}

in_backends && /^}$/ {
	in_backends = 0
}

{ print }

END {
	if (widgets != 12 || backends != 2) {
		print "unexpected CIX SOF topology: " widgets \
		      " widgets and " backends " back ends" > "/dev/stderr"
		exit 1
	}
}
