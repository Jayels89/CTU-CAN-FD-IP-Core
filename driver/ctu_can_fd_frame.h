// SPDX-License-Identifier: GPL-2.0+
/*******************************************************************************
 *
 * CTU CAN FD IP Core
 * Copyright (C) 2015-2018
 *
 * Authors:
 *     Ondrej Ille <ondrej.ille@gmail.com>
 *     Martin Jerabek <martin.jerabek01@gmail.com>
 *
 * Project advisors:
 *	Jiri Novak <jnovak@fel.cvut.cz>
 *	Pavel Pisa <pisa@cmp.felk.cvut.cz>
 *
 * Department of Measurement         (http://meas.fel.cvut.cz/)
 * Faculty of Electrical Engineering (http://www.fel.cvut.cz)
 * Czech Technical University        (http://www.cvut.cz/)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301, USA.
 *
 ******************************************************************************/

/* This file is autogenerated, DO NOT EDIT! */

#ifndef __CTU_CAN_FD_CAN_FD_FRAME_FORMAT__
#define __CTU_CAN_FD_CAN_FD_FRAME_FORMAT__

/* CAN_Frame_format memory map */
enum ctu_can_fd_can_frame_format {
	CTU_CAN_FD_FRAME_FORM_W        = 0x0,
	CTU_CAN_FD_IDENTIFIER_W        = 0x4,
	CTU_CAN_FD_TIMESTAMP_L_W       = 0x8,
	CTU_CAN_FD_TIMESTAMP_U_W       = 0xc,
	CTU_CAN_FD_DATA_1_4_W         = 0x10,
	CTU_CAN_FD_DATA_5_8_W         = 0x14,
	CTU_CAN_FD_DATA_61_64_W       = 0x4c,
};


/* Register descriptions: */
union ctu_can_fd_frame_form_w {
	uint32_t u32;
	struct ctu_can_fd_frame_form_w_s {
#ifdef __LITTLE_ENDIAN_BITFIELD
  /* FRAME_FORM_W */
		uint32_t dlc                     : 4;
		uint32_t reserved_4              : 1;
		uint32_t rtr                     : 1;
		uint32_t ide                     : 1;
		uint32_t fdf                     : 1;
		uint32_t tbf                     : 1;
		uint32_t brs                     : 1;
		uint32_t esi_rsv                 : 1;
		uint32_t rwcnt                   : 5;
		uint32_t reserved_31_16         : 16;
#else
		uint32_t reserved_31_16         : 16;
		uint32_t rwcnt                   : 5;
		uint32_t esi_rsv                 : 1;
		uint32_t brs                     : 1;
		uint32_t tbf                     : 1;
		uint32_t fdf                     : 1;
		uint32_t ide                     : 1;
		uint32_t rtr                     : 1;
		uint32_t reserved_4              : 1;
		uint32_t dlc                     : 4;
#endif
	} s;
};

enum ctu_can_fd_frame_form_w_rtr {
	NO_RTR_FRAME       = 0x0,
	RTR_FRAME          = 0x1,
};

enum ctu_can_fd_frame_form_w_ide {
	BASE           = 0x0,
	EXTENDED       = 0x1,
};

enum ctu_can_fd_frame_form_w_fdf {
	NORMAL_CAN       = 0x0,
	FD_CAN           = 0x1,
};

enum ctu_can_fd_frame_form_w_tbf {
	NOT_TIME_BASED       = 0x0,
	TIME_BASED           = 0x1,
};

enum ctu_can_fd_frame_form_w_brs {
	BR_NO_SHIFT       = 0x0,
	BR_SHIFT          = 0x1,
};

enum ctu_can_fd_frame_form_w_esi_rsv {
	ESI_ERR_ACTIVE       = 0x0,
	ESI_ERR_PASIVE       = 0x1,
};

union ctu_can_fd_identifier_w {
	uint32_t u32;
	struct ctu_can_fd_identifier_w_s {
#ifdef __LITTLE_ENDIAN_BITFIELD
  /* IDENTIFIER_W */
		uint32_t identifier_ext         : 18;
		uint32_t identifier_base        : 11;
		uint32_t reserved_31_29          : 3;
#else
		uint32_t reserved_31_29          : 3;
		uint32_t identifier_base        : 11;
		uint32_t identifier_ext         : 18;
#endif
	} s;
};

union ctu_can_fd_timestamp_l_w {
	uint32_t u32;
	struct ctu_can_fd_timestamp_l_w_s {
  /* TIMESTAMP_L_W */
		uint32_t time_stamp_31_0        : 32;
	} s;
};

union ctu_can_fd_timestamp_u_w {
	uint32_t u32;
	struct ctu_can_fd_timestamp_u_w_s {
  /* TIMESTAMP_U_W */
		uint32_t timestamp_l_w          : 32;
	} s;
};

union ctu_can_fd_data_1_4_w {
	uint32_t u32;
	struct ctu_can_fd_data_1_4_w_s {
#ifdef __LITTLE_ENDIAN_BITFIELD
  /* DATA_1_4_W */
		uint32_t data_1                  : 8;
		uint32_t data_2                  : 8;
		uint32_t data_3                  : 8;
		uint32_t data_4                  : 8;
#else
		uint32_t data_4                  : 8;
		uint32_t data_3                  : 8;
		uint32_t data_2                  : 8;
		uint32_t data_1                  : 8;
#endif
	} s;
};

union ctu_can_fd_data_5_8_w {
	uint32_t u32;
	struct ctu_can_fd_data_5_8_w_s {
#ifdef __LITTLE_ENDIAN_BITFIELD
  /* DATA_5_8_W */
		uint32_t data_5                  : 8;
		uint32_t data_6                  : 8;
		uint32_t data_7                  : 8;
		uint32_t data_8                  : 8;
#else
		uint32_t data_8                  : 8;
		uint32_t data_7                  : 8;
		uint32_t data_6                  : 8;
		uint32_t data_5                  : 8;
#endif
	} s;
};

union ctu_can_fd_data_61_64_w {
	uint32_t u32;
	struct ctu_can_fd_data_61_64_w_s {
#ifdef __LITTLE_ENDIAN_BITFIELD
  /* DATA_61_64_W */
		uint32_t data_61                 : 8;
		uint32_t data_62                 : 8;
		uint32_t data_63                 : 8;
		uint32_t data_64                 : 8;
#else
		uint32_t data_64                 : 8;
		uint32_t data_63                 : 8;
		uint32_t data_62                 : 8;
		uint32_t data_61                 : 8;
#endif
	} s;
};

#endif
