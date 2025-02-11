import os
from .utils import *

def key_pattern():
    return "{experiment}-{period}-{run}-{datatype}-{timestamp}"

def processing_pattern():
    return key_pattern()+'-{processing_step}'

def par_pattern():
    return "{experiment}-{period}-{run}-{datatype}-{timestamp}-pars_{name}"

def par_overwrite_pattern():
    return "{experiment}-{period}-{run}-{datatype}-{timestamp}-pars_{name}-overwrite"

def get_pattern_tier_daq(setup):
    return os.path.join(f"{tier_daq_path(setup)}", "{datatype}", "{period}", "{run}", "{experiment}-{period}-{run}-{datatype}-{timestamp}.orca")

def get_pattern_tier_raw(setup):
    return os.path.join(f"{tier_raw_path(setup)}", "{datatype}","{period}", "{run}", "{experiment}-{period}-{run}-{datatype}-{timestamp}-tier_raw.lh5")

def get_pattern_tier_tcm(setup):
    return os.path.join(f"{tier_tcm_path(setup)}", "{datatype}","{period}", "{run}", "{experiment}-{period}-{run}-{datatype}-{timestamp}-tier_tcm.lh5")

def get_pattern_tier_dsp(setup):
    return os.path.join(f"{tier_dsp_path(setup)}", "{datatype}","{period}", "{run}", "{experiment}-{period}-{run}-{datatype}-{timestamp}-tier_dsp.lh5")

def get_pattern_tier_hit(setup):
    return os.path.join(f"{tier_hit_path(setup)}", "{datatype}","{period}", "{run}", "{experiment}-{period}-{run}-{datatype}-{timestamp}-tier_hit.lh5")

def get_pattern_tier_evt(setup):
    return os.path.join(f"{tier_evt_path(setup)}", "{datatype}","{period}", "{run}", "{experiment}-{period}-{run}-{datatype}-{timestamp}-tier_evt.lh5")

def get_pattern_tier(setup,tier):
    if tier =="daq":
        return get_pattern_tier_daq(setup)
    elif tier =="raw":
        return get_pattern_tier_raw(setup)
    elif tier =="tcm":
        return get_pattern_tier_tcm(setup)
    elif tier =="dsp":
        return get_pattern_tier_dsp(setup)
    elif tier =="hit":
        return get_pattern_tier_hit(setup)
    elif tier =="evt":
        return get_pattern_tier_evt(setup)
    else:
        raise Exception("invalid tier")

def get_pattern_par_raw(setup, name=None):
    if name is not None:
        return os.path.join(f"{par_raw_path(setup)}",  "cal", "{period}", "{run}", "{experiment}-{period}-{run}-cal-{timestamp}-pars_raw_"+name+".json")
    else:
        return os.path.join(f"{par_raw_path(setup)}", "cal", "{period}", "{run}", "{experiment}-{period}-{run}-cal-{timestamp}-pars_raw.json")

def get_pattern_par_tcm(setup, name=None):
    if name is not None:
        return os.path.join(f"{par_tcm_path(setup)}",  "cal", "{period}", "{run}", "{experiment}-{period}-{run}-cal-{timestamp}-pars_tcm_"+name+".json")
    else:
        return os.path.join(f"{par_tcm_path(setup)}",  "cal", "{period}", "{run}", "{experiment}-{period}-{run}-cal-{timestamp}-pars_tcm.json")

def get_pattern_par_dsp(setup, name=None):
    if name is not None:
        return os.path.join(f"{par_dsp_path(setup)}",  "cal", "{period}", "{run}", "{experiment}-{period}-{run}-cal-{timestamp}-pars_dsp_"+name+".json")
    else:
        return os.path.join(f"{par_dsp_path(setup)}", "cal", "{period}", "{run}", "{experiment}-{period}-{run}-cal-{timestamp}-pars_dsp.json")

def get_pattern_par_hit(setup, name=None):
    if name is not None:
        return os.path.join(f"{par_hit_path(setup)}",  "cal", "{period}", "{run}", "{experiment}-{period}-{run}-cal-{timestamp}-pars_hit_"+name+".json")
    else:
        return os.path.join(f"{par_hit_path(setup)}",  "cal", "{period}", "{run}", "{experiment}-{period}-{run}-cal-{timestamp}-pars_hit.json")

def get_pattern_par_evt(setup, name=None):
    if name is not None:
        return os.path.join(f"{par_evt_path(setup)}", "cal", "{period}", "{run}", "{experiment}-{period}-{run}-cal-{timestamp}-pars_evt_"+name+".json")
    else:
        return os.path.join(f"{par_evt_path(setup)}", "cal", "{period}", "{run}", "{experiment}-{period}-{run}-cal-{timestamp}-pars_evt.json")


def get_pattern_pars(setup, tier, name = None):
    if tier =="raw":
        return get_pattern_par_raw(setup, name=name)
    elif tier =="tcm":
        return get_pattern_par_tcm(setup, name=name)
    elif tier =="dsp":
        return get_pattern_par_dsp(setup, name=name)
    elif tier =="hit":
        return get_pattern_par_hit(setup, name=name)
    elif tier =="evt":
        return get_pattern_par_evt(setup, name=name)
    else:
        raise Exception("invalid tier")

def get_pattern_pars_overwrite(setup, tier, name = None):
    if name is not None:
        return os.path.join(f"{par_overwrite_path(setup)}", tier,  "cal", "{period}", "{run}", "{experiment}-{period}-{run}-cal-{timestamp}-pars_"+tier+"_"+name+"-overwrite.json")
    else:
        return os.path.join(f"{par_overwrite_path(setup)}", tier,  "cal", "{period}", "{run}", "{experiment}-{period}-{run}-cal-{timestamp}-pars_"+tier+"-overwrite.json")

def get_pattern_pars_tmp_channel(setup, tier, name=None):
    if name =="energy_grid":
        return os.path.join(f"{tmp_par_path(setup)}", tier, "cal",  "{period}", "{run}" , "pars_dsp_energy_grid", "{channel}", "{experiment}-{period}-{run}-{channel}-{peak}-pars_dsp_energy_grid.pkl")
    elif name == "energy_grid_at_qbb":
        return os.path.join(f"{tmp_par_path(setup)}", tier, "cal",  "{period}",  "{run}", "pars_dsp_energy_grid", "{channel}", "{experiment}-{period}-{run}-{channel}-qbb-pars_dsp_energy_grid.pkl")
    else:
        if name is None:
            return os.path.join(f"{tmp_par_path(setup)}", tier, "cal",  "{period}", "{run}" ,  "{channel}" , "pars_"+tier, "{experiment}-{period}-{run}-{channel}-pars_"+tier+".json")
        else:
            return os.path.join(f"{tmp_par_path(setup)}", tier, "cal",  "{period}", "{run}" ,  "{channel}" , "pars_"+tier+"_"+name, "{experiment}-{period}-{run}-{channel}-pars_"+tier+"_"+name+".json")

def get_pattern_plts_tmp_channel(setup, tier, name):
    return os.path.join(f"{plts_path(setup)}", "plts",tier,"cal", "{period}", "{run}","{experiment}-{period}-{run}-{channel}-plts_"+tier+"_"+name+".pdf")

def get_pattern_plts(setup, tier, name):
    return os.path.join(f"{plts_path(setup)}", tier,"cal", "{period}", "{run}", "{experiment}-{period}-{run}-plts_"+tier+"_"+name+".pdf")

def get_energy_grids_pattern_combine(setup):
    return os.path.join(f"{tmp_par_path(setup)}", "dsp", "cal",  "{{period}}", "{{run}}" , "energy_grid", "{{channel}}", "{{experiment}}-{{period}}-{{run}}-{{channel}}-{peak}-pars_dsp_energy_grid.pkl")

