onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib Ascii_Text_BROM_opt

do {wave.do}

view wave
view structure
view signals

do {Ascii_Text_BROM.udo}

run -all

quit -force
