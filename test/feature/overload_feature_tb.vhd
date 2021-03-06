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
--  Feature test for generation of overload frame.
--
--------------------------------------------------------------------------------
-- Revision History:
--
--    30.6.2016   Created file
--    06.02.2018  Modified to work with the IP-XACT generated memory map
--------------------------------------------------------------------------------

context work.ctu_can_synth_context;
context work.ctu_can_test_context;

use lib.pkg_feature_exec_dispath.all;

package overload_feature is
    procedure overload_feature_exec(
        variable    o               : out    feature_outputs_t;
        signal      so              : out    feature_signal_outputs_t;
        signal      rand_ctr        : inout  natural range 0 to RAND_POOL_SIZE;
        signal      iout            : in     instance_outputs_arr_t;
        signal      mem_bus         : inout  mem_bus_arr_t;
        signal      bus_level       : in     std_logic
	);
end package;


package body overload_feature is
    procedure overload_feature_exec(
        variable    o               : out    feature_outputs_t;
        signal      so              : out    feature_signal_outputs_t;
        signal      rand_ctr        : inout  natural range 0 to RAND_POOL_SIZE;
        signal      iout            : in     instance_outputs_arr_t;
        signal      mem_bus         : inout  mem_bus_arr_t;
        signal      bus_level       : in     std_logic
    ) is
        variable r_data             :        std_logic_vector(31 downto 0) :=
                                                 (OTHERS => '0');
        variable CAN_frame          :        SW_CAN_frame_type;
        variable frame_sent         :        boolean := false;
        variable ctr_1              :        natural;
        variable ctr_2              :        natural;
        variable ID_1           	:        natural := 1;
        variable ID_2           	:        natural := 2;
        variable rand_val           :        real;
        variable retr_th            :        natural;
        variable mode_backup        :        std_logic_vector(31 downto 0) :=
                                                 (OTHERS => '0');
    begin
        o.outcome := true;

        ------------------------------------------------------------------------
        -- Wait until unit comes out of integration. This is to make sure
        -- that first frame will be transmitted and not that transition to
        -- "interframe" will be from "off", directly after integration! This
        -- transition goes directly to "interm_idle" and bit is correctly
        -- interpreted as SOF and not Overload flag!
        ------------------------------------------------------------------------
        wait_rand_cycles(rand_ctr, mem_bus(1).clk_sys, 2500, 3000);

        ------------------------------------------------------------------------
        -- Generate CAN Frame and start transmission
        ------------------------------------------------------------------------
        CAN_generate_frame(rand_ctr, CAN_frame);
        CAN_send_frame(CAN_frame, 1, ID_1, mem_bus(1), frame_sent);

        for i in 0 to 3 loop

            --------------------------------------------------------------------
            -- Wait until intermission field starts
            --------------------------------------------------------------------
            wait until protocol_type'VAL(to_integer(unsigned(
                iout(1).stat_bus(STAT_PC_STATE_HIGH downto STAT_PC_STATE_LOW)))) =
                        interframe;

            --------------------------------------------------------------------
            -- Inject dominant bit during the intermission
            --------------------------------------------------------------------
            so.bl_inject <= DOMINANT;
            so.bl_force  <= true;

            --------------------------------------------------------------------
            -- Wait for change on protocol state
            --------------------------------------------------------------------
            wait until protocol_type'VAL(to_integer(unsigned(
                   iout(1).stat_bus(STAT_PC_STATE_HIGH downto STAT_PC_STATE_LOW)))) /=
                        interframe;

            --------------------------------------------------------------------
            -- Check if overload started
            --------------------------------------------------------------------
            check(protocol_type'VAL(to_integer(unsigned(
                  iout(1).stat_bus(STAT_PC_STATE_HIGH downto STAT_PC_STATE_LOW)))) =
                  overload, "Overload Frame did not start");

            so.bl_inject <= RECESSIVE;
            so.bl_force <= false;
        end loop;

        CAN_wait_frame_sent(ID_1, mem_bus(1));
    end procedure;

end package body;