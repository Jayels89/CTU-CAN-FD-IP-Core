--------------------------------------------------------------------------------
--
-- CTU CAN FD IP Core
-- Copyright (C) 2015-2018 Ondrej Ille <ondrej.ille@gmail.com>
--
-- Project advisors and co-authors:
-- 	Jiri Novak <jnovak@fel.cvut.cz>
-- 	Pavel Pisa <pisa@cmp.felk.cvut.cz>
-- 	Martin Jerabek <jerabma7@fel.cvut.cz>
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
--  Data length Code feature test. Verifies functionality of maximal DLC equal
--  to 8 for CAN 2.0 frames.
--
--  Test sequence:
--    1. Generate CAN 2.0 Frame and set DLC higher than 8. Set higher data
--       bytes accordingly!
--    2. Send the CAN Frame via Node 1.
--    3. Verify that frame received by Node 2, has only DLC 8 received and
--       that higher data bytes are 0!
--------------------------------------------------------------------------------
-- Revision History:
--    14.7.2018   Created file
--------------------------------------------------------------------------------

Library ieee;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.ALL;
USE ieee.math_real.ALL;
use work.CANconstants.all;
USE work.CANtestLib.All;
USE work.randomLib.All;
use work.pkg_feature_exec_dispath.all;

use work.CAN_FD_register_map.all;

package data_length_code_feature is
    procedure data_length_code_feature_exec(
        variable    o               : out    feature_outputs_t;
        signal      so              : out    feature_signal_outputs_t;
        signal      rand_ctr        : inout  natural range 0 to RAND_POOL_SIZE;
        signal      iout            : in     instance_outputs_arr_t;
        signal      mem_bus         : inout  mem_bus_arr_t;
        signal      bus_level       : in     std_logic
    );
end package;


package body data_length_code_feature is
    procedure data_length_code_feature_exec(
        variable    o               : out    feature_outputs_t;
        signal      so              : out    feature_signal_outputs_t;
        signal      rand_ctr        : inout  natural range 0 to RAND_POOL_SIZE;
        signal      iout            : in     instance_outputs_arr_t;
        signal      mem_bus         : inout  mem_bus_arr_t;
        signal      bus_level       : in     std_logic
    ) is
        constant ID_1               :        natural := 1;
        constant ID_2               :        natural := 2;
        variable CAN_frame          :        SW_CAN_frame_type;
        variable CAN_frame_2        :        SW_CAN_frame_type  := 
                    (0, (OTHERS => (OTHERS => '0')), "0000", 0, '0', '0',
                     '0', '0', '0', (OTHERS => '0'), 0);
        variable frame_sent         :        boolean;
    begin
        o.outcome := true;

        ------------------------------------------------------------------------
        -- Generate CAN Frame and force CAN 2.0 and DLC higher than 8!
        ------------------------------------------------------------------------
        CAN_generate_frame(rand_ctr, CAN_frame);
        rand_logic_vect_v(rand_ctr, CAN_frame.dlc, 0.5);
        CAN_frame.dlc(3) := '1';
        CAN_frame.frame_format := NORMAL_CAN;
        decode_dlc(CAN_frame.dlc, CAN_frame.data_length);
        for i in 0 to data_length - 1 loop
            rand_logic_vect_v(rand_ctr, CAN_frame.data(i), 0.5);
        end loop;

        ------------------------------------------------------------------------
        -- Send frame by Node 1
        ------------------------------------------------------------------------
        CAN_send_frame(CAN_frame, 1, ID_1, mem_bus(1), frame_sent);
        CAN_wait_frame_sent(ID_1, mem_bus(1));
        wait for 500 ns;

        ------------------------------------------------------------------------
        -- Read frame by Node 2 and Check that DLC is equal to 8 and higher
        -- data bytes are 0!
        ------------------------------------------------------------------------
        CAN_read_frame(CAN_frame_2, ID_2, mem_bus(2));
        if (CAN_frame_2.dlc /= "1000") then
            o.outcome := false;
            report "Invalid DLC received!" severity error;
        end if;

        for i in 8 to 63 loop
            if (CAN_frame_2.data(i) /= "00000000") then
                report "Byte index " & integer'image(i) & " not zero!"
                    severity error;
            end if;
        end loop;

  end procedure;

end package body;
