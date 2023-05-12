mod error;
mod mnist_core;
mod user_part;

use crate::mnist_core::{MnistImage, MnistOps};
use crate::user_part::MnistUserPartition;
use anyhow::Context;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::time::Duration;

const MNIST_ARFF_FILE: &str = "mnist_784.arff";
const MNIST_ARFF_NUM_ROWS: usize = 70_000;
const MNIST_IMAGE_LEN: usize = 784;
const MNIST_ARFF_ROW_LEN: usize = MNIST_IMAGE_LEN + 1;
const ARFF_DATA_TOKEN: &str = "@DATA";
const BATCH_SIZE: usize = 10_000;

const _TEST_IMAGE: [u8; 784] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 2, 5, 4, 4, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 6, 7, 7, 7, 7, 7, 6, 6, 6, 6, 6, 6, 6, 6, 5, 1, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 2, 3, 2, 3, 5, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 4, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 2, 2, 2, 1, 0, 7, 7, 3, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 7, 6, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 2, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 7, 7, 1, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 7, 7, 1, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 7, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 7, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 7, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 7, 7, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 7, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 7, 6, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 7, 7, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 7, 7, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 7, 7, 7, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 7, 7, 6, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 7, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
];

fn parse_mnist_arff(file_path: &str) -> anyhow::Result<Vec<Vec<u8>>> {
    let file = File::open(file_path)?;
    let mut reader = BufReader::new(file);

    // Skip until the next line after the DATA token
    loop {
        let mut line = String::new();
        reader
            .read_line(&mut line)
            .context("read ARFF to the end, no data")?;
        if line.contains(ARFF_DATA_TOKEN) {
            break;
        }
    }

    // Read the rows until the end of file
    let mut rows = Vec::with_capacity(MNIST_ARFF_NUM_ROWS);
    for line in &mut reader.lines() {
        let line_content = line?;
        let fields: Vec<&str> = line_content.split(',').collect();
        let mut row: Vec<u8> = Vec::with_capacity(MNIST_ARFF_ROW_LEN);
        for field in fields {
            let b: u8 = field.parse().context("field isn't a u8")?;
            row.push(b);
        }
        rows.push(row);
    }

    Ok(rows)
}

fn main() -> anyhow::Result<()> {
    let rows = parse_mnist_arff(MNIST_ARFF_FILE)?;
    let user_part = MnistUserPartition::new()?;

    if !user_part.mnist.is_idle()? {
        anyhow::bail!("MNIST core is busy");
    }

    let mut images: Vec<MnistImage> = Vec::with_capacity(BATCH_SIZE);
    let mut classes: Vec<u8> = Vec::with_capacity(BATCH_SIZE);
    for row in rows.iter().skip(42_000).take(BATCH_SIZE) {
        let mut im: [u8; MNIST_IMAGE_LEN] = [0; MNIST_IMAGE_LEN];
        im.clone_from_slice(&row[0..MNIST_IMAGE_LEN]);

        // Reduce grey levels to 0..10.
        for pix in &mut im {
            *pix /= 24;
        }

        images.push(MnistImage(im));
        classes.push(row[MNIST_IMAGE_LEN]);
    }
    println!("The first image:\n{}", images[0]);

    user_part.mnist.init(BATCH_SIZE)?;
    user_part.mnist.write_dataset(&images)?;
    user_part.mnist.start()?;
    let t_done = user_part
        .mnist
        .poll_done_every_1ms(Duration::from_secs(5))?;

    println!("Done in {t_done}ms. Reading the results...");
    let results = user_part.mnist.read_results(BATCH_SIZE)?;

    let n_matches = results
        .iter()
        .zip(classes.iter())
        .filter(|(r, c)| r == c)
        .count();
    let success_rate: f64 = 100.0 * n_matches as f64 / BATCH_SIZE as f64;
    println!("Success rate {success_rate}");

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_row_length() {
        let rows = parse_mnist_arff(MNIST_ARFF_FILE).expect("cannot parse ARFF");
        for row in &rows {
            assert_eq!(row.len(), MNIST_ARFF_ROW_LEN);
        }
    }
}
