#!/bin/bash

#source _setenv.sh

NAME=`echo $1 | sed -e 's,\.csv,,g'`

gnuplot << eor
set terminal png size $REPORT_CHART_WIDTH, $REPORT_CHART_HEIGHT noenhanced
set title "$NAME Response Time Histogram"
set output "$NAME.png"
set boxwidth 0.75
set style fill
set datafile separator ";"
set xtic rotate by -45 scale 0
set xlabel "Percentile [%]"
set ylabel "Response Time [ms]"
set yrange [0:*]
set grid
plot "$1" using 2:xtic(1) with boxes t "", "" using 0:(\$2+15):(sprintf("%3.0f",\$2)) with labels t ""
eor
