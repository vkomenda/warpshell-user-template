use crate::error::Result;
use std::time::Duration;
use std::{fmt, iter, mem};
use warpshell::{BaseParam, BasedCtrlOps, BasedDmaOps, DmaBuffer};

pub const MNIST_IMAGE_LEN: usize = 784;

#[derive(Copy, Clone, Debug, PartialEq)]
#[repr(transparent)]
pub struct MnistImage(pub [u8; MNIST_IMAGE_LEN]);

impl fmt::Display for MnistImage {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let mut rows = String::new();
        for i in 0..28 {
            let row: String = self.0[i * 28..(i + 1) * 28 - 1]
                .iter()
                .map(|byte| format!("{:02X} ", byte))
                .chain(iter::once("\n".to_string()))
                .collect();

            rows += &row;
        }
        write!(f, "{rows}")
    }
}

#[derive(Copy, Clone, Debug, PartialEq)]
#[repr(u64)]
pub enum MnistReg {
    Control = 0,
    GlobalInterruptEnable = 0x04,
    IpInterruptEnable = 0x08,
    IpInterruptStatus = 0x0c,
    ImLow = 0x10,
    ImHigh = 0x14,
    OutRLow = 0x1c,
    OutRHigh = 0x20,
}

#[repr(u32)]
pub enum ControlRegBit {
    /// bit 0  - ap_start (Read/Write/COH)
    Start = 1 << 0,
    /// bit 1  - ap_done (Read/COR)
    Done = 1 << 1,
    /// bit 2  - ap_idle (Read)
    Idle = 1 << 2,
    /// ap_ready (Read/COR)
    Ready = 1 << 3,
    /// bit 7  - auto_restart (Read/Write)
    AutoRestart = 1 << 7,
    /// bit 9  - interrupt (Read)
    Interrupt = 1 << 9,
}

pub trait GetMnistIf<C: BasedCtrlOps, Input: BasedDmaOps, Output: BasedDmaOps> {
    fn get_ctrl_if(&self) -> &C;
    fn get_input_dma_if(&self) -> &Input;
    fn get_output_dma_if(&self) -> &Output;
}

impl<C, Input, Output, T> MnistOps<C, Input, Output> for T
where
    C: BasedCtrlOps,
    Input: BasedDmaOps + BaseParam,
    Output: BasedDmaOps + BaseParam,
    T: GetMnistIf<C, Input, Output>,
{
}

pub trait MnistOps<C, Input, Output>: GetMnistIf<C, Input, Output>
where
    C: BasedCtrlOps,
    Input: BasedDmaOps + BaseParam,
    Output: BasedDmaOps + BaseParam,
{
    /// Reads the value of a MNIST control register.
    fn get_mnist_reg(&self, reg: MnistReg) -> Result<u32> {
        Ok(self.get_ctrl_if().based_ctrl_read_u32(reg as u64)?)
    }

    /// Writes a value to a MNIST control register.
    fn set_mnist_reg(&self, reg: MnistReg, value: u32) -> Result<()> {
        Ok(self.get_ctrl_if().based_ctrl_write_u32(reg as u64, value)?)
    }

    fn init(&self, num_results: usize) -> Result<()> {
        let im_addr = Input::BASE_ADDR;
        self.set_mnist_reg(MnistReg::ImHigh, (im_addr >> 32) as u32)?;
        self.set_mnist_reg(MnistReg::ImLow, im_addr as u32)?;
        let out_addr = Output::BASE_ADDR;
        self.set_mnist_reg(MnistReg::OutRHigh, (out_addr >> 32) as u32)?;
        self.set_mnist_reg(MnistReg::OutRLow, out_addr as u32)?;

        // Erase any previous results
        let mut buf = DmaBuffer::new(num_results);
        for _ in 0..num_results {
            buf.get_mut().push(0xff);
        }
        self.get_output_dma_if().based_dma_write(&buf, 0)?;

        Ok(())
    }

    fn start(&self) -> Result<()> {
        self.set_mnist_reg(MnistReg::Control, ControlRegBit::Start as u32)?;
        Ok(())
    }

    fn write_dataset(&self, images: &[MnistImage]) -> Result<()> {
        let mut buf = DmaBuffer::new(mem::size_of_val(images));
        for im in images {
            buf.get_mut().extend_from_slice(&im.0);
        }
        Ok(self.get_input_dma_if().based_dma_write(&buf, 0)?)
    }

    fn read_results(&self, num_results: usize) -> Result<Vec<u8>> {
        let mut buf = DmaBuffer::new(num_results);
        for _ in 0..num_results {
            buf.get_mut().push(0);
        }
        self.get_output_dma_if().based_dma_read(&mut buf, 0)?;
        Ok(unsafe { dma_buffer_to_vec_u8(buf) })
    }

    /// Checks if the core is in IDLE state.
    fn is_idle(&self) -> Result<bool> {
        let mask = ControlRegBit::Idle as u32;
        Ok(self.get_mnist_reg(MnistReg::Control)? & mask == mask)
    }

    /// Polls for the done status at 1 ms intervals for `duration`, returning the elapsed number of polls.
    fn poll_done_every_1ms(&self, duration: Duration) -> Result<usize> {
        let mask = ControlRegBit::Done as u32;
        let period = Duration::from_millis(1);
        Ok(self.get_ctrl_if().poll_reg_mask_sleep(
            MnistReg::Control as u64,
            mask,
            mask,
            usize::try_from(duration.as_nanos() / period.as_nanos()).unwrap_or_default(),
            period,
        )?)
    }
}

unsafe fn dma_buffer_to_vec_u8(mut buf: DmaBuffer) -> Vec<u8> {
    let ptr = buf.get_mut().as_mut_ptr();
    let len = buf.get().len();
    let cap = buf.get().capacity();

    mem::forget(buf);

    Vec::from_raw_parts(ptr as *mut u8, len, cap)
}
