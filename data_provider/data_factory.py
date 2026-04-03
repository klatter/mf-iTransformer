"""Factory that maps CLI dataset names to dataset classes and constructs
dataset + dataloader pairs.

The `data_provider` function centralizes dataset selection and ensures that
mixed-frequency datasets receive the additional `downsampling_rates` and
`freq_groups_list` arguments expected by the mixed dataset constructors.
"""

from data_provider.data_loader import Dataset_ETT_hour, Dataset_ETT_hour_Mixed, Dataset_ETT_minute, Dataset_ETT_minute_Mixed, Dataset_Custom, Dataset_Custom_Mixed, Dataset_Solar, Dataset_PEMS, \
    Dataset_Pred
from torch.utils.data import DataLoader

data_dict = {
    'ETTh1': Dataset_ETT_hour,
    'ETTh2': Dataset_ETT_hour,
    'ETTh1_mixed': Dataset_ETT_hour_Mixed,
    'ETTh2_mixed': Dataset_ETT_hour_Mixed,
    'ETTm1': Dataset_ETT_minute,
    'ETTm2': Dataset_ETT_minute,
    'ETTm1_mixed': Dataset_ETT_minute_Mixed,
    'ETTm2_mixed': Dataset_ETT_minute_Mixed,
    'Solar': Dataset_Solar,
    'PEMS': Dataset_PEMS,
    'custom': Dataset_Custom,
    'custom_mixed': Dataset_Custom_Mixed,
}


def data_provider(args, flag):
    """Return a (dataset, dataloader) pair for the given split `flag`.

    - `args` is expected to be the parsed CLI namespace used by `run.py`.
    - `flag` is one of `'train'`, `'val'`, `'test'`, or `'pred'`.

    For mixed datasets (`args.data` ending with `_mixed`) additional keyword
    arguments are forwarded to the dataset constructor:
    `downsampling_rates` and `freq_groups` (parsed as `freq_groups_list` by
    `run.py`).
    """

    Data = data_dict[args.data]
    timeenc = 0 if args.embed != 'timeF' else 1

    if flag == 'test':
        shuffle_flag = False
        drop_last = True
        batch_size = 1  # bsz=1 for evaluation
        freq = args.freq
    elif flag == 'pred':
        shuffle_flag = False
        drop_last = False
        batch_size = 1
        freq = args.freq
        Data = Dataset_Pred
    else:
        shuffle_flag = True
        drop_last = True
        batch_size = args.batch_size  # bsz for train and valid
        freq = args.freq

    if args.data.endswith('_mixed') and flag != 'pred':
        data_set = Data(
            root_path=args.root_path,
            data_path=args.data_path,
            flag=flag,
            size=[args.seq_len, args.label_len, args.pred_len],
            features=args.features,
            target=args.target,
            scale=getattr(args, 'scale', True),
            timeenc=timeenc,
            freq=freq,
            downsampling_rates=getattr(args, 'downsampling_rates', [1]),
            freq_groups=getattr(args, 'freq_groups_list', []),
        )
    else:
        data_set = Data(
            root_path=args.root_path,
            data_path=args.data_path,
            flag=flag,
            size=[args.seq_len, args.label_len, args.pred_len],
            features=args.features,
            target=args.target,
            timeenc=timeenc,
            freq=freq,
        )
    print(flag, len(data_set))
    data_loader = DataLoader(
        data_set,
        batch_size=batch_size,
        shuffle=shuffle_flag,
        num_workers=args.num_workers,
        drop_last=drop_last)
    return data_set, data_loader
