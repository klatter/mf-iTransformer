import pandas as pd
import numpy as np
import argparse
import os


def process_dataset(input_path, output_prefix, low_freq_cols, ratio=24):
    """Generate sparse (mixed) and dense (high) variants from a high-frequency CSV."""
    print(f"Processing {input_path}...")
    df = pd.read_csv(input_path)

    if 'date' in df.columns:
        df['date'] = pd.to_datetime(df['date'])

    missing_cols = [col for col in low_freq_cols if col not in df.columns]
    if missing_cols:
        raise ValueError(f"Columns not found in input dataset: {missing_cols}")

    input_dir = os.path.dirname(os.path.abspath(input_path))
    base_name = os.path.basename(output_prefix)

    # =========================================================
    # 1. MIXED DATASET (For mf-iTransformer)
    # Native sparse data: low-frequency columns get NaNs
    # everywhere except at the exact ratio interval.
    # =========================================================
    df_mixed = df.copy()
    mask = df_mixed.index % ratio != 0
    df_mixed.loc[mask, low_freq_cols] = np.nan

    mixed_out_path = os.path.join(input_dir, f"{base_name}_mixed.csv")
    df_mixed.to_csv(mixed_out_path, index=False)
    print(f"  -> Saved MIXED (sparse) dataset:  {mixed_out_path}")

    # =========================================================
    # 2. HIGH DATASET (For standard iTransformer baseline)
    # The NaNs are interpolated to create a dense dataset,
    # upsampling the low frequencies to match the high frequency.
    # =========================================================
    df_high = df_mixed.copy()
    df_high[low_freq_cols] = df_high[low_freq_cols].interpolate(method='linear')
    df_high[low_freq_cols] = df_high[low_freq_cols].bfill()  # Fill any leading NaNs.

    high_out_path = os.path.join(input_dir, f"{base_name}_high.csv")
    df_high.to_csv(high_out_path, index=False)
    print(f"  -> Saved HIGH (upsampled) dataset: {high_out_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate Mixed and High MF Datasets')
    parser.add_argument('--dataset', type=str, required=True, help='Path to original CSV')
    parser.add_argument('--output_prefix', type=str, required=True, help='Prefix for output files')
    parser.add_argument(
        '--low_freq_cols',
        type=str,
        required=True,
        help='Comma separated list of columns to treat as low frequency',
    )
    parser.add_argument('--ratio', type=int, default=24, help='Downsampling ratio')

    args = parser.parse_args()
    cols_to_downsample = [col.strip() for col in args.low_freq_cols.split(',')]

    process_dataset(
        input_path=args.dataset,
        output_prefix=args.output_prefix,
        low_freq_cols=cols_to_downsample,
        ratio=args.ratio
    )