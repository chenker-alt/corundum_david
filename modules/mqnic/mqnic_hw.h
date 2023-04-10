/* SPDX-License-Identifier: BSD-2-Clause-Views */
/*
 * Copyright 2019-2021, The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *    1. Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation
 * are those of the authors and should not be interpreted as representing
 * official policies, either expressed or implied, of The Regents of the
 * University of California.
 */

#ifndef MQNIC_HW_H
#define MQNIC_HW_H

#include <linux/types.h>

#define MQNIC_MAX_IRQ 256

#define MQNIC_MAX_IF 8
#define MQNIC_MAX_PORTS 8
#define MQNIC_MAX_SCHED 8

#define MQNIC_MAX_FRAGS 8

#define MQNIC_MAX_EVENT_RINGS   256
#define MQNIC_MAX_TX_RINGS      8192
#define MQNIC_MAX_TX_CPL_RINGS  8192
#define MQNIC_MAX_RX_RINGS      8192
#define MQNIC_MAX_RX_CPL_RINGS  8192

#define MQNIC_MAX_I2C_ADAPTERS 4

#define MQNIC_BOARD_ID_NETFPGA_SUME  0x10ee7028
#define MQNIC_BOARD_ID_AU50          0x10ee9032
#define MQNIC_BOARD_ID_AU200         0x10ee90c8
#define MQNIC_BOARD_ID_AU250         0x10ee90fa
#define MQNIC_BOARD_ID_AU280         0x10ee9118
#define MQNIC_BOARD_ID_VCU108        0x10ee806c
#define MQNIC_BOARD_ID_VCU118        0x10ee9076
#define MQNIC_BOARD_ID_VCU1525       0x10ee95f5
#define MQNIC_BOARD_ID_ZCU106        0x10ee906a
#define MQNIC_BOARD_ID_DE10_AGILEX   0x1172b00a
#define MQNIC_BOARD_ID_XUPP3R        0x12ba9823
#define MQNIC_BOARD_ID_250SOC        0x198a250e
#define MQNIC_BOARD_ID_FB2CG_KU15P   0x1c2ca00e
#define MQNIC_BOARD_ID_NEXUS_K35_S   0x1ce40003
#define MQNIC_BOARD_ID_NEXUS_K3P_S   0x1ce40009
#define MQNIC_BOARD_ID_NEXUS_K3P_Q   0x1ce4000a
#define MQNIC_BOARD_ID_DNPCIE_40G_KU 0x17df1a00
#define MQNIC_BOARD_ID_ADM_PCIE_9V3  0x41449003

// Register blocks
#define MQNIC_RB_REG_TYPE      0x00
#define MQNIC_RB_REG_VER       0x04
#define MQNIC_RB_REG_NEXT_PTR  0x08

#define MQNIC_RB_FW_ID_TYPE            0xFFFFFFFF
#define MQNIC_RB_FW_ID_VER             0x00000100
#define MQNIC_RB_FW_ID_REG_FPGA_ID     0x0C
#define MQNIC_RB_FW_ID_REG_FW_ID       0x10
#define MQNIC_RB_FW_ID_REG_FW_VER      0x14
#define MQNIC_RB_FW_ID_REG_BOARD_ID    0x18
#define MQNIC_RB_FW_ID_REG_BOARD_VER   0x1C
#define MQNIC_RB_FW_ID_REG_BUILD_DATE  0x20
#define MQNIC_RB_FW_ID_REG_GIT_HASH    0x24
#define MQNIC_RB_FW_ID_REG_REL_INFO    0x28

#define MQNIC_RB_GPIO_TYPE          0x0000C100
#define MQNIC_RB_GPIO_VER           0x00000100
#define MQNIC_RB_GPIO_REG_GPIO_IN   0x0C
#define MQNIC_RB_GPIO_REG_GPIO_OUT  0x10

#define MQNIC_RB_I2C_TYPE      0x0000C110
#define MQNIC_RB_I2C_VER       0x00000100
#define MQNIC_RB_I2C_REG_CTRL  0x0C

#define MQNIC_REG_GPIO_I2C_SCL_IN         0x00000001
#define MQNIC_REG_GPIO_I2C_SCL_OUT        0x00000002
#define MQNIC_REG_GPIO_I2C_SDA_IN         0x00000100
#define MQNIC_REG_GPIO_I2C_SDA_OUT        0x00000200

#define MQNIC_RB_SPI_FLASH_TYPE        0x0000C120
#define MQNIC_RB_SPI_FLASH_VER         0x00000200
#define MQNIC_RB_SPI_FLASH_REG_FORMAT  0x0C
#define MQNIC_RB_SPI_FLASH_REG_CTRL_0  0x10
#define MQNIC_RB_SPI_FLASH_REG_CTRL_1  0x14

#define MQNIC_RB_BPI_FLASH_TYPE        0x0000C121
#define MQNIC_RB_BPI_FLASH_VER         0x00000200
#define MQNIC_RB_BPI_FLASH_REG_FORMAT  0x0C
#define MQNIC_RB_BPI_FLASH_REG_ADDR    0x10
#define MQNIC_RB_BPI_FLASH_REG_DATA    0x14
#define MQNIC_RB_BPI_FLASH_REG_CTRL    0x18

#define MQNIC_RB_ALVEO_BMC_TYPE      0x0000C140
#define MQNIC_RB_ALVEO_BMC_VER       0x00000100
#define MQNIC_RB_ALVEO_BMC_REG_ADDR  0x0C
#define MQNIC_RB_ALVEO_BMC_REG_DATA  0x10

#define MQNIC_RB_GECKO_BMC_TYPE        0x0000C141
#define MQNIC_RB_GECKO_BMC_VER         0x00000100
#define MQNIC_RB_GECKO_BMC_REG_STATUS  0x0C
#define MQNIC_RB_GECKO_BMC_REG_DATA    0x10
#define MQNIC_RB_GECKO_BMC_REG_CMD     0x14

#define MQNIC_RB_STATS_TYPE        0x0000C006
#define MQNIC_RB_STATS_VER         0x00000100
#define MQNIC_RB_STATS_REG_OFFSET  0x0C
#define MQNIC_RB_STATS_REG_COUNT   0x10
#define MQNIC_RB_STATS_REG_STRIDE  0x14
#define MQNIC_RB_STATS_REG_FLAGS   0x18

#define MQNIC_RB_IRQ_TYPE        0x0000C007
#define MQNIC_RB_IRQ_VER         0x00000100

#define MQNIC_RB_CLK_INFO_TYPE         0x0000C008
#define MQNIC_RB_CLK_INFO_VER          0x00000100
#define MQNIC_RB_CLK_INFO_COUNT        0x0C
#define MQNIC_RB_CLK_INFO_REF_NOM_PER  0x10
#define MQNIC_RB_CLK_INFO_CLK_NOM_PER  0x18
#define MQNIC_RB_CLK_INFO_CLK_FREQ     0x1C
#define MQNIC_RB_CLK_INFO_FREQ_BASE    0x20

#define MQNIC_RB_PHC_TYPE               0x0000C080
#define MQNIC_RB_PHC_VER                0x00000100
#define MQNIC_RB_PHC_REG_CTRL           0x0C
#define MQNIC_RB_PHC_REG_CUR_FNS        0x10
#define MQNIC_RB_PHC_REG_CUR_NS         0x14
#define MQNIC_RB_PHC_REG_CUR_SEC_L      0x18
#define MQNIC_RB_PHC_REG_CUR_SEC_H      0x1C
#define MQNIC_RB_PHC_REG_GET_FNS        0x20
#define MQNIC_RB_PHC_REG_GET_NS         0x24
#define MQNIC_RB_PHC_REG_GET_SEC_L      0x28
#define MQNIC_RB_PHC_REG_GET_SEC_H      0x2C
#define MQNIC_RB_PHC_REG_SET_FNS        0x30
#define MQNIC_RB_PHC_REG_SET_NS         0x34
#define MQNIC_RB_PHC_REG_SET_SEC_L      0x38
#define MQNIC_RB_PHC_REG_SET_SEC_H      0x3C
#define MQNIC_RB_PHC_REG_PERIOD_FNS     0x40
#define MQNIC_RB_PHC_REG_PERIOD_NS      0x44
#define MQNIC_RB_PHC_REG_NOM_PERIOD_FNS 0x48
#define MQNIC_RB_PHC_REG_NOM_PERIOD_NS  0x4C
#define MQNIC_RB_PHC_REG_ADJ_FNS        0x50
#define MQNIC_RB_PHC_REG_ADJ_NS         0x54
#define MQNIC_RB_PHC_REG_ADJ_COUNT      0x58
#define MQNIC_RB_PHC_REG_ADJ_ACTIVE     0x5C

#define MQNIC_RB_PHC_PEROUT_TYPE              0x0000C081
#define MQNIC_RB_PHC_PEROUT_VER               0x00000100
#define MQNIC_RB_PHC_PEROUT_REG_CTRL          0x0C
#define MQNIC_RB_PHC_PEROUT_REG_START_FNS     0x10
#define MQNIC_RB_PHC_PEROUT_REG_START_NS      0x14
#define MQNIC_RB_PHC_PEROUT_REG_START_SEC_L   0x18
#define MQNIC_RB_PHC_PEROUT_REG_START_SEC_H   0x1C
#define MQNIC_RB_PHC_PEROUT_REG_PERIOD_FNS    0x20
#define MQNIC_RB_PHC_PEROUT_REG_PERIOD_NS     0x24
#define MQNIC_RB_PHC_PEROUT_REG_PERIOD_SEC_L  0x28
#define MQNIC_RB_PHC_PEROUT_REG_PERIOD_SEC_H  0x2C
#define MQNIC_RB_PHC_PEROUT_REG_WIDTH_FNS     0x30
#define MQNIC_RB_PHC_PEROUT_REG_WIDTH_NS      0x34
#define MQNIC_RB_PHC_PEROUT_REG_WIDTH_SEC_L   0x38
#define MQNIC_RB_PHC_PEROUT_REG_WIDTH_SEC_H   0x3C

#define MQNIC_RB_IF_TYPE            0x0000C000
#define MQNIC_RB_IF_VER             0x00000100
#define MQNIC_RB_IF_REG_OFFSET      0x0C
#define MQNIC_RB_IF_REG_COUNT       0x10
#define MQNIC_RB_IF_REG_STRIDE      0x14
#define MQNIC_RB_IF_REG_CSR_OFFSET  0x18

#define MQNIC_RB_IF_CTRL_TYPE            0x0000C001
#define MQNIC_RB_IF_CTRL_VER             0x00000400
#define MQNIC_RB_IF_CTRL_REG_FEATURES    0x0C
#define MQNIC_RB_IF_CTRL_REG_PORT_COUNT  0x10
#define MQNIC_RB_IF_CTRL_REG_SCHED_COUNT 0x14
#define MQNIC_RB_IF_CTRL_REG_MAX_TX_MTU  0x20
#define MQNIC_RB_IF_CTRL_REG_MAX_RX_MTU  0x24
#define MQNIC_RB_IF_CTRL_REG_TX_MTU      0x28
#define MQNIC_RB_IF_CTRL_REG_RX_MTU      0x2C

#define MQNIC_IF_FEATURE_RSS      (1 << 0)
#define MQNIC_IF_FEATURE_PTP_TS   (1 << 4)
#define MQNIC_IF_FEATURE_TX_CSUM  (1 << 8)
#define MQNIC_IF_FEATURE_RX_CSUM  (1 << 9)
#define MQNIC_IF_FEATURE_RX_HASH  (1 << 10)

#define MQNIC_RB_RX_QUEUE_MAP_TYPE             0x0000C090
#define MQNIC_RB_RX_QUEUE_MAP_VER              0x00000200
#define MQNIC_RB_RX_QUEUE_MAP_REG_CFG          0x0C
#define MQNIC_RB_RX_QUEUE_MAP_CH_OFFSET        0x10
#define MQNIC_RB_RX_QUEUE_MAP_CH_STRIDE        0x10
#define MQNIC_RB_RX_QUEUE_MAP_CH_REG_OFFSET    0x00
#define MQNIC_RB_RX_QUEUE_MAP_CH_REG_RSS_MASK  0x04
#define MQNIC_RB_RX_QUEUE_MAP_CH_REG_APP_MASK  0x08

#define MQNIC_RB_EVENT_QM_TYPE        0x0000C010
#define MQNIC_RB_EVENT_QM_VER         0x00000200
#define MQNIC_RB_EVENT_QM_REG_OFFSET  0x0C
#define MQNIC_RB_EVENT_QM_REG_COUNT   0x10
#define MQNIC_RB_EVENT_QM_REG_STRIDE  0x14

#define MQNIC_RB_TX_QM_TYPE        0x0000C020
#define MQNIC_RB_TX_QM_VER         0x00000200
#define MQNIC_RB_TX_QM_REG_OFFSET  0x0C
#define MQNIC_RB_TX_QM_REG_COUNT   0x10
#define MQNIC_RB_TX_QM_REG_STRIDE  0x14

#define MQNIC_RB_TX_CQM_TYPE        0x0000C030
#define MQNIC_RB_TX_CQM_VER         0x00000200
#define MQNIC_RB_TX_CQM_REG_OFFSET  0x0C
#define MQNIC_RB_TX_CQM_REG_COUNT   0x10
#define MQNIC_RB_TX_CQM_REG_STRIDE  0x14

#define MQNIC_RB_RX_QM_TYPE        0x0000C021
#define MQNIC_RB_RX_QM_VER         0x00000200
#define MQNIC_RB_RX_QM_REG_OFFSET  0x0C
#define MQNIC_RB_RX_QM_REG_COUNT   0x10
#define MQNIC_RB_RX_QM_REG_STRIDE  0x14

#define MQNIC_RB_RX_CQM_TYPE        0x0000C031
#define MQNIC_RB_RX_CQM_VER         0x00000200
#define MQNIC_RB_RX_CQM_REG_OFFSET  0x0C
#define MQNIC_RB_RX_CQM_REG_COUNT   0x10
#define MQNIC_RB_RX_CQM_REG_STRIDE  0x14

#define MQNIC_RB_PORT_TYPE        0x0000C002
#define MQNIC_RB_PORT_VER         0x00000200
#define MQNIC_RB_PORT_REG_OFFSET  0x0C

#define MQNIC_RB_PORT_CTRL_TYPE           0x0000C003
#define MQNIC_RB_PORT_CTRL_VER            0x00000200
#define MQNIC_RB_PORT_CTRL_REG_FEATURES   0x0C
#define MQNIC_RB_PORT_CTRL_REG_TX_STATUS  0x10
#define MQNIC_RB_PORT_CTRL_REG_RX_STATUS  0x14

#define MQNIC_RB_SCHED_BLOCK_TYPE        0x0000C004
#define MQNIC_RB_SCHED_BLOCK_VER         0x00000300
#define MQNIC_RB_SCHED_BLOCK_REG_OFFSET  0x0C

#define MQNIC_RB_SCHED_RR_TYPE           0x0000C040
#define MQNIC_RB_SCHED_RR_VER            0x00000100
#define MQNIC_RB_SCHED_RR_REG_OFFSET     0x0C
#define MQNIC_RB_SCHED_RR_REG_CH_COUNT   0x10
#define MQNIC_RB_SCHED_RR_REG_CH_STRIDE  0x14
#define MQNIC_RB_SCHED_RR_REG_CTRL       0x18
#define MQNIC_RB_SCHED_RR_REG_DEST       0x1C

#define MQNIC_RB_SCHED_CTRL_TDMA_TYPE           0x0000C050
#define MQNIC_RB_SCHED_CTRL_TDMA_VER            0x00000100
#define MQNIC_RB_SCHED_CTRL_TDMA_REG_OFFSET     0x0C
#define MQNIC_RB_SCHED_CTRL_TDMA_REG_CH_COUNT   0x10
#define MQNIC_RB_SCHED_CTRL_TDMA_REG_CH_STRIDE  0x14
#define MQNIC_RB_SCHED_CTRL_TDMA_REG_CTRL       0x18
#define MQNIC_RB_SCHED_CTRL_TDMA_REG_TS_COUNT   0x1C

#define MQNIC_RB_TDMA_SCH_TYPE                     0x0000C060
#define MQNIC_RB_TDMA_SCH_VER                      0x00000100
#define MQNIC_RB_TDMA_SCH_REG_TS_COUNT             0x0C
#define MQNIC_RB_TDMA_SCH_REG_CTRL                 0x10
#define MQNIC_RB_TDMA_SCH_REG_STATUS               0x14
#define MQNIC_RB_TDMA_SCH_REG_SCH_START_FNS        0x20
#define MQNIC_RB_TDMA_SCH_REG_SCH_START_NS         0x24
#define MQNIC_RB_TDMA_SCH_REG_SCH_START_SEC_L      0x28
#define MQNIC_RB_TDMA_SCH_REG_SCH_START_SEC_H      0x2C
#define MQNIC_RB_TDMA_SCH_REG_SCH_PERIOD_FNS       0x30
#define MQNIC_RB_TDMA_SCH_REG_SCH_PERIOD_NS        0x34
#define MQNIC_RB_TDMA_SCH_REG_SCH_PERIOD_SEC_L     0x38
#define MQNIC_RB_TDMA_SCH_REG_SCH_PERIOD_SEC_H     0x3C
#define MQNIC_RB_TDMA_SCH_REG_TS_PERIOD_FNS        0x40
#define MQNIC_RB_TDMA_SCH_REG_TS_PERIOD_NS         0x44
#define MQNIC_RB_TDMA_SCH_REG_TS_PERIOD_SEC_L      0x48
#define MQNIC_RB_TDMA_SCH_REG_TS_PERIOD_SEC_H      0x4C
#define MQNIC_RB_TDMA_SCH_REG_ACTIVE_PERIOD_FNS    0x50
#define MQNIC_RB_TDMA_SCH_REG_ACTIVE_PERIOD_NS     0x54
#define MQNIC_RB_TDMA_SCH_REG_ACTIVE_PERIOD_SEC_L  0x58
#define MQNIC_RB_TDMA_SCH_REG_ACTIVE_PERIOD_SEC_H  0x5C

#define MQNIC_RB_APP_INFO_TYPE    0x0000C005
#define MQNIC_RB_APP_INFO_VER     0x00000200
#define MQNIC_RB_APP_INFO_REG_ID  0x0C

#define MQNIC_QUEUE_BASE_ADDR_REG       0x00
#define MQNIC_QUEUE_ACTIVE_LOG_SIZE_REG 0x08
#define MQNIC_QUEUE_CPL_QUEUE_INDEX_REG 0x0C
#define MQNIC_QUEUE_HEAD_PTR_REG        0x10
#define MQNIC_QUEUE_TAIL_PTR_REG        0x18

#define MQNIC_QUEUE_ACTIVE_MASK 0x80000000

#define MQNIC_CPL_QUEUE_BASE_ADDR_REG       0x00
#define MQNIC_CPL_QUEUE_ACTIVE_LOG_SIZE_REG 0x08
#define MQNIC_CPL_QUEUE_INTERRUPT_INDEX_REG 0x0C
#define MQNIC_CPL_QUEUE_HEAD_PTR_REG        0x10
#define MQNIC_CPL_QUEUE_TAIL_PTR_REG        0x18

#define MQNIC_CPL_QUEUE_ACTIVE_MASK 0x80000000

#define MQNIC_CPL_QUEUE_ARM_MASK 0x80000000
#define MQNIC_CPL_QUEUE_CONT_MASK 0x40000000

#define MQNIC_EVENT_QUEUE_BASE_ADDR_REG       0x00
#define MQNIC_EVENT_QUEUE_ACTIVE_LOG_SIZE_REG 0x08
#define MQNIC_EVENT_QUEUE_INTERRUPT_INDEX_REG 0x0C
#define MQNIC_EVENT_QUEUE_HEAD_PTR_REG        0x10
#define MQNIC_EVENT_QUEUE_TAIL_PTR_REG        0x18

#define MQNIC_EVENT_QUEUE_ACTIVE_MASK 0x80000000

#define MQNIC_EVENT_QUEUE_ARM_MASK 0x80000000
#define MQNIC_EVENT_QUEUE_CONT_MASK 0x40000000

#define MQNIC_EVENT_TYPE_TX_CPL 0x0000
#define MQNIC_EVENT_TYPE_RX_CPL 0x0001

#define MQNIC_DESC_SIZE 16
#define MQNIC_CPL_SIZE 32
#define MQNIC_EVENT_SIZE 32

struct mqnic_desc {
	__le16 rsvd0;
	__le16 tx_csum_cmd;
	__le32 len;
	__le64 addr;
};

struct mqnic_cpl {
	__le16 queue;
	__le16 index;
	__le16 len;
	__le16 rsvd0;
	__le32 ts_ns;
	__le16 ts_s;
	__le16 rx_csum;
	__le32 rx_hash;
	__u8 rx_hash_type;
	__u8 port;
	__u8 rsvd2;
	__u8 rsvd3;
	__le32 rsvd4;
	__le32 phase;
};

struct mqnic_event {
	__le16 type;
	__le16 source;
	__le32 rsvd0;
	__le32 rsvd1;
	__le32 rsvd2;
	__le32 rsvd3;
	__le32 rsvd4;
	__le32 rsvd5;
	__le32 phase;
};

#endif /* MQNIC_HW_H */
