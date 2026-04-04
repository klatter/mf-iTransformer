import numpy as np


def RSE(pred, true):
    return np.sqrt(np.nansum((true - pred) ** 2)) / np.sqrt(np.nansum((true - np.nanmean(true)) ** 2))


def CORR(pred, true):
    # Pearson correlation, NaN-safe
    true_mean = np.nanmean(true, axis=0)
    pred_mean = np.nanmean(pred, axis=0)
    u = np.nansum((true - true_mean) * (pred - pred_mean), axis=0)
    d = np.sqrt(np.nansum((true - true_mean) ** 2, axis=0) * np.nansum((pred - pred_mean) ** 2, axis=0))
    return np.nanmean(u / d)


def MAE(pred, true):
    return np.nanmean(np.abs(pred - true))


def MSE(pred, true):
    return np.nanmean((pred - true) ** 2)


def RMSE(pred, true):
    return np.sqrt(MSE(pred, true))


def MAPE(pred, true):
    return np.nanmean(np.abs((pred - true) / true))


def MSPE(pred, true):
    return np.nanmean(np.square((pred - true) / true))


def metric(pred, true):
    mae = MAE(pred, true)
    mse = MSE(pred, true)
    rmse = RMSE(pred, true)
    mape = MAPE(pred, true)
    mspe = MSPE(pred, true)

    return mae, mse, rmse, mape, mspe
