use thiserror::Error;
use warpshell::{xdma::Error as XdmaError, Error as WarpshellError};

pub type Result<T> = std::result::Result<T, Error>;

#[derive(Error, Debug)]
pub enum Error {
    #[error("Warpshell error: {0}")]
    WarpshellError(#[from] WarpshellError),
    #[error("XDMA error: {0}")]
    XdmaError(#[from] XdmaError),
}
