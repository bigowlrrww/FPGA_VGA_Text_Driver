onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+Screen_Array_BRAM -L xil_defaultlib -L xpm -L blk_mem_gen_v8_4_3 -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.Screen_Array_BRAM xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {Screen_Array_BRAM.udo}

run -all

endsim

quit -force
