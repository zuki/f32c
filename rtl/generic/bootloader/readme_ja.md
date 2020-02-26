# ブートローダ

ソースからブートを作成し、loader.binを生成する方法

1. makefile環境変数を設定(unix)

  ```bash
  cd f32c/src/tools
  . ./makefiles.sh
  ```

2. コンパイル（ボードマネージャからArduino jsonをインストール済みと仮定）

  以下を実行するとMIPSリトルエンディアンのバイナリブートローダを生成する。

  TODO: ビッグエンディアンの生成方法  -- arduinoのplatform.txtにあるoptionsを参照

  ```bash
  cd f32c/src/boot/sio
  PATH=$PATH:~/.arduino15/packages/FPGArduino/tools/f32c-compiler/1.0.0/bin make
  ```

3. バイナリのloader.binをvhdに変換

  ```bash
  f32c/src/tools/bin2vhdl.sh loader.bin > loader.vhd.include
  ```

4. `loader.vhd.include`を適当なファイルにコピペ。

  x"00", x"00", x"00", x"00", x"21", x"40", x"00", x"00"のような行を以下のブートローダファイルにコピペ
    - boot_sio_mi32el.vhd -- 汎用f32c bootloader
    - boot_rom_mi32el.vhd -- SPI flash rom f32c bootloader (ULX2Sボード用)

# ユーザ定義のブートローダ

パイプラインをプライマリステートに初期化するために、f32cのリセット後、少なくとも最初の5つの命令はNOP（0x00000000）にする必要があります。

初期コードではスタックポインタを正しく設定する必要があります。（Arduino-IDEでコンパイルした）ユーザコードをブートローダとして置き換える必要がある場合は、もとのブートローダにあるNOPで始まりスタックを初期化する部分は残してください。

# SPI config flashからのブート

これはまだ適切には実装されていないため、ここでは適切に作成する方法を提案します。

ほとんどのFPGAデバイスは、SPI config Flashを使用して電源投入時に初期ビットストリームをロードします。通常、Flashの内容は実行中のビットストリームからアクセス（読み書き）可能です。また、通常、Flashにはユーザコード用に十分な空き領域があります。

SPI config Flashからf32cコードを起動するために、（通常はvhdlからプリロードされru
）Flash対応初期ブートローダーは次のようにする必要があります。

    1. look for first 32-bit signature "C0 DE F3 2C" every 64K
       (at address 0x10000, 0x20000, ... etc. bytes expect signature)
    2. after signature read 32-bit RAM starting address
    3. after RAM starting address read 32-bit content length
    4. copy following content (length bytes) to RAM starting address
       calculating CRC
    5. after content read 32-bit CRC
    6. if CRC is correct, jump to RAM starting address,
    7. optionally look for another signature starting from
       next 64K until all flash is searched
