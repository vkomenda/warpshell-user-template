use crate::error::Result;
use crate::mnist_core::GetMnistIf;
use warpshell::{
    xdma::{CtrlChannel, DmaChannel, GetCtrlChannel, GetDmaChannel, CTRL_CHANNEL, DMA_CHANNEL0},
    BaseParam,
};
use warpshell_derive::{GetCtrlChannel, GetDmaChannel};

pub struct MnistUserPartition<'a> {
    pub mnist: Mnist<'a>,
}

impl<'a> MnistUserPartition<'a> {
    pub fn new() -> Result<Self> {
        let ctrl_channel = CTRL_CHANNEL.get_or_init()?;
        let dma_channel = DMA_CHANNEL0.get_or_init()?;
        let mnist = Mnist {
            ctrl_if: MnistCtrlIf { ctrl_channel },
            input_dma_if: MnistInputDmaIf { dma_channel },
            output_dma_if: MnistOutputDmaIf { dma_channel },
        };

        Ok(Self { mnist })
    }
}

pub struct Mnist<'a> {
    /// Control interface
    ctrl_if: MnistCtrlIf<'a>,
    /// Input DMA interface
    input_dma_if: MnistInputDmaIf<'a>,
    /// Output DMA interface
    output_dma_if: MnistOutputDmaIf<'a>,
}

impl<'a> GetMnistIf<MnistCtrlIf<'a>, MnistInputDmaIf<'a>, MnistOutputDmaIf<'a>> for Mnist<'a> {
    fn get_ctrl_if(&self) -> &MnistCtrlIf<'a> {
        &self.ctrl_if
    }

    fn get_input_dma_if(&self) -> &MnistInputDmaIf<'a> {
        &self.input_dma_if
    }

    fn get_output_dma_if(&self) -> &MnistOutputDmaIf<'a> {
        &self.output_dma_if
    }
}

#[derive(GetCtrlChannel)]
pub struct MnistCtrlIf<'a> {
    /// Control channel
    ctrl_channel: &'a CtrlChannel,
}

impl<'a> BaseParam for MnistCtrlIf<'a> {
    const BASE_ADDR: u64 = 0x0000_0000;
}

#[derive(GetDmaChannel)]
pub struct MnistInputDmaIf<'a> {
    /// DMA channel
    dma_channel: &'a DmaChannel,
}

impl<'a> BaseParam for MnistInputDmaIf<'a> {
    const BASE_ADDR: u64 = 0x0000_0000_0000_0000;
}

#[derive(GetDmaChannel)]
pub struct MnistOutputDmaIf<'a> {
    /// DMA channel
    dma_channel: &'a DmaChannel,
}

impl<'a> BaseParam for MnistOutputDmaIf<'a> {
    const BASE_ADDR: u64 = 0x0000_0001_0000_0000;
}
