#include <ap_int.h>

void compute_sum(ap_uint<256> *in, ap_uint<256> *out, int n_elements) {
    ap_uint<256> sum = 0;
    for (int i = 0; i < n_elements; i++) {
#pragma HLS PIPELINE II=1
        sum += in[i];
        out[i] = sum;
    }
}

void axi_sum_example(
    ap_uint<256> *in,
    ap_uint<256> *out,
    int n_elements,
    int n_rounds
) {
#pragma HLS INTERFACE mode=s_axilite port=return
#pragma HLS INTERFACE mode=s_axilite port=n_elements
#pragma HLS INTERFACE mode=s_axilite port=n_rounds
#pragma HLS INTERFACE mode=m_axi port=in offset=slave max_write_burst_length=16 bundle=gmem
#pragma HLS INTERFACE mode=m_axi port=out offset=slave max_write_burst_length=16 bundle=gmem

    for (int i = 0; i < n_rounds; i++) {
        compute_sum(in, out, n_elements);
    }
}
