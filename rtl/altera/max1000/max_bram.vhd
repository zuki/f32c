--
-- Copyright (c) 2015 Marko Zec, University of Zagreb
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
-- OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
-- LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
-- OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
-- SUCH DAMAGE.
--
-- $Id$
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.f32c_pack.all;

entity max_bram is
    generic (
        -- ISA
        C_arch: integer := ARCH_MI32;

        -- Main clock freq, in multiples of 12 MHz
        C_clk_freq: integer := 100;

        -- SoC configuration options
        C_bram_size: integer := 32;

        -- Debugging
        C_debug: boolean := false;

        -- SoC configuration
        C_simple_in: integer  := 20;
        C_simple_out: integer :=  8;
        C_gpio: integer       := 18
    );
    port (
        clk_12m:   in std_logic;
        uart_tx:   out std_logic;
        uart_rx:   in std_logic;
        led:       out std_logic_vector(7 downto 0);
        user_btn:  in std_logic;
        sw:        in std_logic_vector(3 downto 0);
        gpio:      inout std_logic_vector(17 downto 0)
    );
end max_bram;

architecture Behavioral of max_bram is

    signal clk: std_logic;
    signal btns: std_logic_vector(15 downto 0);

begin
    clock: entity work.pll_100m
    port map (
        inclk0 => clk_12m,
        c0 => clk
    );

    -- generic BRAM glue
    glue_bram: entity work.glue_bram
    generic map (
        C_clk_freq => C_clk_freq,
        C_arch => C_arch,
        C_bram_size => C_bram_size,
        C_debug => C_debug,
        C_simple_in => C_simple_in,
        C_simple_out => C_simple_out,
        C_gpio => C_gpio
    )
    port map (
        clk => clk,
        sio_txd(0) => uart_tx,
        sio_rxd(0) => uart_rx,
        sio_break(0) => open,
--        gpio(31 downto 18) => open,
        gpio(17 downto 0) => gpio,
        spi_miso => "",
        simple_out(7 downto 0) => led,
--        simple_out(31 downto 8) => open,
        simple_in(15 downto 0) => btns,
        simple_in(19 downto 16) => sw
--        simple_in(31 downto 20) => open
    );

    btns <= x"000" & "000" & not user_btn;
end Behavioral;
