# f32c Cソースコード - コンパイルの方法

f32cはMIPS ISAのサブセットを使用するため、MIPSコンパイラにパッチを適用する必要があります。 RISC-Vコンパイラはおそらく（最新版でも）動作しますが、コンパイラとリンカに必要な最新のオプションセットを知る必要があります。そして、これは開発中に変更されることがよくあります:)

コンパイラとパッチをダウンロードして、ソースからコンパイルすることもできますが、もっとも早い方法はarduinoをインストールし、ボードマネージャからfpgarduinoサポートをインストールすることです。コンパイラバイナリは以下に置かれます。

```bash
    ~username/.arduino15/packages/FPGArduino/tools/f32c-compiler/1.0.0/bin
```

その後、次のように実行します（"username.."は自身のログイン名に置き換えてください）。

```bash
    $ cd f32c/src/tools
    $ . ./makefiles.sh
    *** Setting environment for f32c make ***

    makeが正常に実行されるために、スクリプト名の前にドットスラッシュを付けて実行する必要があります。

    . ./makefiles.sh

    これは以下を実行しています。

    export MAKEFILES=/home/username/src/fpga/fpgarduino/f32c/src/tools/../conf/f32c.mk

    $ PATH=$PATH:~username/.arduino15/packages/FPGArduino/tools/f32c-compiler/1.0.0/bin/

    $ cd f32c/src/lib/src
    $ make
```
