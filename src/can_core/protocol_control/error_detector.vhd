--------------------------------------------------------------------------------
-- 
-- CTU CAN FD IP Core
-- Copyright (C) 2015-2018
-- 
-- Authors:
--     Ondrej Ille <ondrej.ille@gmail.com>
--     Martin Jerabek <martin.jerabek01@gmail.com>
-- 
-- Project advisors: 
-- 	Jiri Novak <jnovak@fel.cvut.cz>
-- 	Pavel Pisa <pisa@cmp.felk.cvut.cz>
-- 
-- Department of Measurement         (http://meas.fel.cvut.cz/)
-- Faculty of Electrical Engineering (http://www.fel.cvut.cz)
-- Czech Technical University        (http://www.cvut.cz/)
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this VHDL component and associated documentation files (the "Component"),
-- to deal in the Component without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Component, and to permit persons to whom the
-- Component is furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Component.
-- 
-- THE COMPONENT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHTHOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE COMPONENT OR THE USE OR OTHER DEALINGS
-- IN THE COMPONENT.
-- 
-- The CAN protocol is developed by Robert Bosch GmbH and protected by patents.
-- Anybody who wants to implement this IP core on silicon has to obtain a CAN
-- protocol license from Bosch.
-- 
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Purpose:
--  Error detector.
--------------------------------------------------------------------------------
-- Revision History:
--    29.3.2019   Created file
--------------------------------------------------------------------------------

Library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

Library work;
use work.id_transfer.all;
use work.can_constants.all;
use work.can_components.all;
use work.can_types.all;
use work.cmn_lib.all;
use work.drv_stat_pkg.all;
use work.endian_swap.all;
use work.reduce_lib.all;

use work.CAN_FD_register_map.all;
use work.CAN_FD_frame_format.all;

entity error_detector is
    generic(
        -- Reset polarity
        G_RESET_POLARITY        :     std_logic := '0';
        
        -- Pipeline should be inserted on Error signalling
        G_ERR_VALID_PIPELINE    :     boolean
    );
    port(
        -----------------------------------------------------------------------
        -- Clock and Asynchronous Reset
        -----------------------------------------------------------------------
        -- System clock
        clk_sys                 :in   std_logic;

        -- Asynchronous reset
        res_n                   :in   std_logic;

        -----------------------------------------------------------------------
        -- Data-path interface
        -----------------------------------------------------------------------
        -- Actual TX Data
        tx_data                 :in   std_logic;
        
        -- Actual RX Data
        rx_data                 :in   std_logic;
        
        -----------------------------------------------------------------------
        -- Error sources
        -----------------------------------------------------------------------
        -- Bit error
        bit_error               :in   std_logic;
        
        -- Stuff error
        stuff_error             :in   std_logic;
        
        -- Form Error
        form_error              :in   std_logic;
        
        -- ACK Error
        ack_error               :in   std_logic;
        
        -----------------------------------------------------------------------
        -- CRC comparison data
        -----------------------------------------------------------------------
        -- Received CRC
        rx_crc                  :in   std_logic_vector(20 downto 0);
        
        -- Calculated CRC
        calc_crc                :in   std_logic_vector(20 downto 0);
        
        -- Received Stuff count (Gray coded)
        rx_stuff_count          :in   std_logic_vector(3 downto 0);
        
        -- Counted stuff count (Gray coded)
        calc_stuff_count        :in   std_logic_vector(3 downto 0);

        -----------------------------------------------------------------------
        -- Control signals
        -----------------------------------------------------------------------
        -- Bit error enable
        bit_error_enable        :in   std_logic;

        -- Stuff error enable
        stuff_error_enable      :in   std_logic;

        -- Fixed Bit stuffing method
        fixed_stuff             :in   std_logic;

        -- Error position field (from Protocol control)
        err_pos                 :in   std_logic_vector(4 downto 0);

        -- Perform CRC Check
        crc_check               :in   std_logic;

        -- Clear CRC Error flag
        crc_clear_error_flag    :in   std_logic;

        -- CRC Source (CRC15, CRC17, CRC21)
        crc_src                 :in   std_logic_vector(1 downto 0);

        -- FD Type (ISO FD, NON-ISO FD)
        drv_fd_type             :in   std_logic;

        -- Arbitration field is being transmitted / received
        is_arbitration          :in   std_logic;

        -- Unit is transmitter of frame
        is_transmitter          :in   std_logic;

        -- Unit is error passive
        is_err_passive          :in   std_logic;

        -----------------------------------------------------------------------
        -- Status output
        -----------------------------------------------------------------------
        -- Error frame request
        err_frm_req             :out  std_logic;

        -- Error detected (for Fault confinement)
        error_detected          :out  std_logic;

        -- Error code capture
        erc_capture             :out  std_logic_vector(7 downto 0);

        -- CRC error
        crc_error               :out  std_logic;

        -- Error counters should remain unchanged
        err_ctrs_unchanged      :out  std_logic
    );
end entity;

architecture rtl of error_detector is

    -- Internal Error valid
    signal err_frm_req_i  : std_logic;

    -- Error capture register
    signal err_type_d     : std_logic_vector(2 downto 0);
    signal err_type_q     : std_logic_vector(2 downto 0);
    signal err_pos_q      : std_logic_vector(5 downto 0);
    
    -- Internal form error
    signal form_error_int : std_logic;

    -- CRC Error detection
    signal crc_error_c    : std_logic;
    signal crc_error_d    : std_logic;
    signal crc_error_q    : std_logic;
    
    -- Stuff counter should be checked
    signal stuff_count_check : std_logic;
    
    -- CRC bits 16-17 should be checked
    signal crc_16_17_check : std_logic;
    
    -- CRC bits 18-21 should be checked
    signal crc_18_21_check : std_logic;

    -- CRC Check results
    signal crc_15_ok       : std_logic;
    signal crc_17_ok       : std_logic;
    signal crc_21_ok       : std_logic;
    signal stuff_count_ok  : std_logic;

begin

    ---------------------------------------------------------------------------
    -- Error frame request. Invoked by each Error type which should cause
    -- Error frame in the following bit!
    ---------------------------------------------------------------------------

    -- Error frame request for any type of error which causes transition to
    -- Error frame in the next bit.
    err_frm_req_i <= '1' when (bit_error = '1' and bit_error_enable = '1') else
                     '1' when (stuff_error = '1' and stuff_error_enable = '1') else
                     '1' when (form_error = '1' or ack_error = '1') else
                     '0';

    -- Fixed stuff error shall be reported as Form Error!
    form_error_int <= '1' when (form_error = '1') else
                      '1' when (stuff_error = '1' and stuff_error_enable = '1' and
                                fixed_stuff = '1') else
                      '0';

    err_pipeline_true_gen : if (G_ERR_VALID_PIPELINE) generate
    begin
        err_valid_reg_proc : process(res_n, clk_sys)
        begin
            if (res_n = G_RESET_POLARITY) then
                err_frm_req <= '0';
            elsif (rising_edge(clk_sys)) then
                err_frm_req <= err_frm_req_i;
            end if;
        end process;
    end generate err_pipeline_true_gen;

    err_pipeline_false_gen : if (not G_ERR_VALID_PIPELINE) generate
    begin
        err_frm_req <= err_frm_req_i;
    end generate err_pipeline_true_gen;

    ---------------------------------------------------------------------------
    -- CRC Check
    ---------------------------------------------------------------------------
    -- Check stuff counters for ISO FD and FD Frames only!
    stuff_count_check <= '1' when (drv_fd_type = ISO_FD) and
                                  (crc_src = CRC17 or crc_src = CRC21)
                             else
                         '0';

    -- Check CRC Bits 16-17 for CRC17 and CRC21
    crc_16_17_check <= '1' when (crc_src = CRC17 or crc_src = CRC21)
                           else
                       '0';

    -- Check CRC Bits 18-21 only for CRC21
    crc_18_21_check <= '1' when (crc_src = CRC21) else
                       '0';

    -- CRC 15 bits check
    crc_15_ok <= '1' when (rx_crc(14 downto 0) = calc_crc(14 downto 0))
                     else
                 '0';

    -- CRC 17 check
    crc_17_ok <= '1' when (rx_crc(16 downto 15) = calc_crc(16 downto 15))
                     else
                 '0';
                 
    -- CRC 21 check
    crc_21_ok <= '1' when (rx_crc(20 downto 17) = calc_crc(20 downto 17))
                     else
                 '0';

    -- Stuff counter OK, including parity!
    stuff_count_ok <= '1' when (rx_stuff_count = calc_stuff_count)
                          else
                      '0';

    -- CRC Error
    crc_error_c <= '1' when (crc_15_ok = '0') or
                            (crc_17_ok = '0' and crc_16_17_check = '1') or
                            (crc_21_ok = '0' and crc_18_21_check = '1') or
                            (stuff_count_ok = '0' and stuff_count_check = '1')
                       else
                   '0';

    crc_error_d <= '0' when (crc_clear_error_flag = '1') else
                   crc_error_c when (crc_check = '1') else
                   crc_error_q;
    
    crc_error_reg_proc : process(clk_sys, res_n)
    begin
        if (res_n = G_RESET_POLARITY) then
            crc_error_q <= '0';
        elsif (rising_edge(clk_sys)) then
            crc_error_q <= crc_error_d;
        end if;
    end process;
    
    --------------------------------------------------------------------------
    -- Error detected for Fault Confinement. Valid when there are:
    --  1. Either Error frame request (Bit, Stuff, ACK, Form Errors)
    --  2. CRC error is just detected (edge).
    ---------------------------------------------------------------------------
    error_detected <= '1' when err_frm_req_i or 
                               (crc_error_c = '1' and crc_error_d = '0')
                          else
                      '0';
                      
    --------------------------------------------------------------------------
    -- Error counters should remain unchanged according to 12.1.4.2 in 
    -- ISO11898-1:2015 in following cases:
    --  1. Error passive transmitter detects ACK error.
    --  2. Transmitter detects stuff error in Arbitration when bit should
    --     have been recessive, but was transmitted dominant!
    --------------------------------------------------------------------------
    err_ctrs_unchanged <= '1' when (ack_error = '1' and is_err_passive = '1')
                              else
                          '1' when (stuff_error = '1' and
                                    stuff_error_enable = '1' and
                                    is_arbitration = '1' and
                                    rx_data = DOMINANT and
                                    tx_data = RECESSIVE)
                              else
                          '0';

    --------------------------------------------------------------------------
    -- Error code, next value
    ---------------------------------------------------------------------------
    err_type_d <= "000" when (bit_error = '1' and bit_error_enable = '1') else
                  "001" when (crc_error_q = '1') else
                  "010" when (form_error_int = '1') else
                  "011" when (ack_error = '1') else
                  "100" when (stuff_error = '1' and stuff_error_enable = '1') else
                  err_type_q;
                  
    ---------------------------------------------------------------------------
    -- Error type register
    ---------------------------------------------------------------------------
    err_type_reg_proc : process(clk_sys, res_n)
    begin
        if (res_n = G_RESET_POLARITY) then
            err_type_q <= "000";
            err_pos_q <= "11111";
        elsif (rising_edge(clk_sys)) then
            if (err_frm_req_i = '1' or crc_error_q = '1') then
                err_type_q <= err_type_d;
                err_pos_q  <= err_pos;
            end if;
        end if;
    end process;

    -- Internal signal to output propagation
    erc_capture <= err_pos_q & err_type_q;
    crc_error <= crc_error_q;
    
    ---------------------------------------------------------------------------
    -- Assertions
    ---------------------------------------------------------------------------
    -- psl default clock is rising_edge(clk_sys);
    
    -- psl crc_src_correct_asrt : assert always
    --  (crc_src = CRC15 or crc_src = CRC17 or crc_src = CRC21)
    -- report "CRC Source has invalid value!"
    -- severity error;

end architecture;