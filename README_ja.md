# f32c

[f32c](/rtl/cpu/README.md)は、RISC-V命令セットまたはMIPS命令セットのサブセットを実行できる、再ターゲット可能なスカラー、パイプライン、32ビットプロセッサコアです。パラメーター化されたVHDLで実装されており、さまざまな面積/速度のトレードオフを備えた合成を可能にし、分岐予測と例外処理制御ブロック、オプションのダイレクトマップトキャッシュを備えています。RTLコードには、マルチポートSDRAMやSRAMコントローラー、コンポジット（PAL）付きビデオフレームバッファ、スプライトとウィンドウ処理を行うためのシンプルな2Dアクセラレーションを備えたHDMI、DVI、VGA出力、浮動小数点ベクトルプロセッサ、SPI、UART、PCMオーディオ、GPIO、PWM出力、タイマなどの[SoC](/rtl/soc/README.md) モジュールも含まれています。さらに、さまざまなメーカの人気のFPGA開発ボード用に調整されたグルーロジックも含まれています。

合成整数ベンチマークにおいて、コードとデータがオンチップブロックRAMに格納された本コアは、3.06 CoreMark/MHzと1.63 DMIPS/MHz（関数のインライン化で1.81 DMIPS/MHz）のスコアを出しました。16 KBの命令キャッシュと4 KBのデータキャッシュを持ち、コードとデータを外部SDRAMに格納するよう構成したコアでは、2.78 CoreMark/MHzと1.31 DMIPS/MHzのスコアを出しました。

タイマとUARTを含むパフォーマンス調整したf32c SoCは1048個の6入力LUTしか占有しません。また、697個のLUT（649ロジック+ 48メモリ）しか消費しない最もコンパクトな構成で合成した場合でもgccで生成されたコードを実行することができます。

浮動小数点ベクトルプロセッサをオプションで合成でき、XilinxのSpartan-6(xc6slx25)と7シリーズ(xc7a35i、xc7a102t、xc7z010)、および、AlteraのCyclone-4(EP4CE22)とMAX-10(10M50DAF)、LatticeのECP3(LFE3-150EA)とECP5(LFE5UM-85F)でテスト済みです。 Artix-7では、3148個のLUT、64K BRAM、38個のDSP乗算器（36個は除算ユニット）を使用し、最大3 MFLOP/MHzを提供します。

Fmaxはコアの構成とFPGAのシリコンに依存し、90 nm FPGA（XilinxのS3E/S3AやLatticeのXP2など）では約115MHz、Artix-7などの6-input LUTを持つ最新世代のFPGAでは最大185MHzに達します。

構成オプションには次があります。

```
C_arch               RISC-V or MIPS ISA
C_big_endian         bus endianess
C_mult_enable        synthesize multipler unit
C_branch_likely      support branch delay slot annulling
C_sign_extend        support sign extension instructions
C_movn_movz          support conditional move instructions
C_ll_sc              support atomic read-modify-write constructs
C_branch_prediction  synthesize branch predictor
C_bp_global_depth    global branch history trace size
C_result_forwarding  synthesize result bypasses
C_load_aligner 	     synthesize load aligner
C_full_shifter 	     pipelined instead of iterative shifer
C_icache_size        instruction cache size (0 to 64 KB)
C_dcache_size        data cache size (0 to 64 KB)
C_debug              synthesize single-stepping debug module
```

[FPGArduino page](http://www.nxlab.fer.hr/fpgarduino)では、Windows、OS-X、Linux用のコンパイル済みのgccベースのツールチェーン、XilinxとAltera、LatticeのさまざまなFPGA用のビルド済みデモビットストリーム、Arduino IDEを使用したRISC-V/MISPS実行可能ファイルのコンパイル方法に関する詳細な説明が提供されています。

VHDLモジュールはすべて[BSDライセンス](LICENSE)です。ソフトウェアライブラリの大部分はFreeBSDから借用していますが、他のプロジェクトから借用したものもあり、MITスタイルのライセンスの対象となる場合もあります。
