# MAX1000ボードへのポーティング

[FPGArduinoのWebページ](http://www.nxlab.fer.hr/fpgarduino/)による

```bash
$ git clone https://github.com/f32c/f32c
$ cd f32c
$ mkdir -p rtl/altera/max1000
$ vi rtl/altera/max1000/max_bram.vhd    //  create a top-level file
$ mkdir -p rtl/proj/altera/max1000/bram
$ create a quartus project, compile and program the .pof file
```

# Arudino IDEで実行

1. 上記Webページの指示に従い Arduino IDE に`Arduino FPGA core`をインストール
2. `Tools`で"Board: Generic FPGA board"を選択し、各種設定を行う
3. ExampleからProgramを選び、compile and program で実行
