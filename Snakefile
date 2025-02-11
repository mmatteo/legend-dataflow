import pathlib, os, json
import scripts as ds
from scripts.util.patterns import *

# Set with `snakemake --configfile=/path/to/your/config.json`
# configfile: "have/to/specify/path/to/your/config.json"

subst_vars_in_snakemake_config(workflow, config)

setup = config["setups"]["l200"]
configs = config_path(setup)
swenv = runcmd(setup)

basedir = workflow.basedir

localrules: do_nothing, autogen_keylist, gen_filelist, autogen_output,  build_channel_keylist

rule do_nothing:
    input:

onstart:
    print("Starting workflow")
    shell(f'rm {pars_path(setup)}/key_resolve.jsonl || true')
    ds.pars_key_resolve.write_par_catalog(setup,['-*-*-*-cal'],os.path.join(pars_path(setup),'key_resolve.jsonl'))

onsuccess:
    print("Workflow finished, no error")
    shell("rm *.gen || true")
    shell(f'rm {log_path(setup)}/*')

#Placeholder, can email or maybe put message in slack
onerror:
    print("An error occurred :( ")


# Auto-generate "all[-{detector}[-{measurement}[-{run}[-{timestamp}]]]].keylist"
# based on available tier0 files.
rule autogen_keylist:
    output:
        temp(os.path.join(log_path(setup),"all{keypart}.filekeylist"))
    params:
        setup = lambda wildcards: setup
    script:
        "scripts/create_keylist.py"

def read_filelist_tcm_cal_channel(wildcards):
    label = f"all-{wildcards.experiment}-{wildcards.period}-{wildcards.run}-cal"
    with checkpoints.gen_filelist.get(label=label, tier="tcm", extension="file").output[0].open() as f:
        files = f.read().splitlines()
        return files
        

rule build_channel_keylist:
    input:
        read_filelist_tcm_cal_channel
    output:
        temp(os.path.join(log_path(setup),"all-{experiment}-{period}-{run}-cal-channels.chankeylist"))
    script:
        "scripts/create_chankeylist.py"


checkpoint gen_filelist:
    input:
        os.path.join(log_path(setup),"{label}.{extension}keylist")
    output:
        os.path.join(log_path(setup),"{label}-{tier}.{extension}list")
    params:
        setup = lambda wildcards: setup
    script:
        "scripts/create_{wildcards.extension}list.py"


def read_filelist(wildcards):
    with checkpoints.gen_filelist.get(label=wildcards.label, tier=wildcards.tier, extension="file").output[0].open() as f:
        files = f.read().splitlines()
        return files 

# Create "{label}-{tier}.gen", based on "{label}.keylist" via
# "{label}-{tier}.filelist". Will implicitly trigger creation of all files
# in "{label}-{tier}.filelist".
# Example: "all[-{detector}[-{measurement}[-{run}[-{timestamp}]]]]-{tier}.gen":
rule autogen_output:
    input:
        read_filelist
    output:
        "{label}-{tier}.gen"
    run:
        pathlib.Path(output[0]).touch()

rule build_raw:
    input:
        get_pattern_tier_daq(setup)
    output:
        get_pattern_tier_raw(setup)
    group: "tier-raw"
    resources:
        runtime=300
    shell:
        "{swenv} python3 {basedir}/scripts/build_raw.py --configs {configs} {input} {output}"

#This rule builds the tcm files each raw file
rule build_tier_tcm:
    input:
        get_pattern_tier_raw(setup)
    output:
        get_pattern_tier_tcm(setup)
    group: "tier-tcm"
    resources:
        runtime=300
    run:
        pathlib.Path(output[0]).touch()

#def read_filelist_raw_cal_channel(wildcards):
#    label = f"all-{wildcards.experiment}-{wildcards.period}-{wildcards.run}-cal"
#    with checkpoints.gen_filelist.get(label=label, tier="raw").output[0].open() as f:
#        files = f.read().splitlines()
#        return files

rule build_pars_dsp_tau:
    input:
        files = os.path.join(log_path(setup),"all-{experiment}-{period}-{run}-cal-raw.filelist")#read_filelist_raw_cal_channel
    params:
        timestamp = "{timestamp}",
        datatype = "{datatype}"
    output:
        decay_const = temp(get_pattern_pars_tmp_channel(setup, "dsp", "decay_constant")),
        plots = temp(get_pattern_plts_tmp_channel(setup, "dsp","decay_constant"))
    group: "pars-dsp"
    resources:
        runtime=300
    shell:
        "{swenv} python3 {basedir}/scripts/pars_dsp_tau.py --configs {configs} --datatype {params.datatype} --timestamp {params.timestamp} --plot_path {output.plots} --output_file {output.decay_const} {input.files} "

#This rule builds all the energy grids used for the energy optimisation using calibration dsp files (These could be temporary?)
rule build_pars_dsp_egrids:
    input:
        files = os.path.join(log_path(setup),"all-{experiment}-{period}-{run}-cal-raw.filelist"),#read_filelist_raw_cal_channel,
        decay_const = get_pattern_pars_tmp_channel(setup, "dsp","decay_constant")
    params:
        timestamp = "{timestamp}",
        datatype = "{datatype}"
    output:
        temp(get_pattern_pars_tmp_channel(setup, "dsp", "energy_grid"))
    group: "pars-dsp-energy"
    resources:
        runtime=300
    shell:
        "{swenv} python3 {basedir}/scripts/pars_dsp_egrids.py --decay_const {input.decay_const} --configs {configs} --datatype {params.datatype} --timestamp {params.timestamp}  --output_path {output} {input.files}"

#This rule builds the optimal energy filter parameters for the dsp using calibration dsp files
rule build_pars_dsp_eopt:
    input:
        files = os.path.join(log_path(setup),"all-{experiment}-{period}-{run}-cal-raw.filelist"),
        peak_files = expand(get_energy_grids_pattern_combine(setup), peak = [238.632,   583.191, 727.330, 860.564, 1620.5, 2614.553]),
        decay_const = get_pattern_pars_tmp_channel(setup, "dsp","decay_constant")
    params:
        timestamp = "{timestamp}",
        datatype = "{datatype}"
    output:
        dsp_pars = temp(get_pattern_pars_tmp_channel(setup, "dsp", "dsp_pars")),
        qbb_grid = temp(get_pattern_pars_tmp_channel(setup, "dsp", "energy_grid_at_qbb")),
        plot_path = temp(get_pattern_plts_tmp_channel(setup, "dsp", "dsp_pars"))
    group: "pars-dsp-energy_opt"
    resources:
        runtime=300
    shell:
        "{swenv} python3 {basedir}/scripts/pars_dsp_eopt.py --final_dsp_pars {output.dsp_pars} --configs {configs} --datatype {params.datatype} --timestamp {params.timestamp}  --raw_filelist {input.files} --decay_const {input.decay_const} --qbb_grid_path {output.qbb_grid} --plot_save_path {output.plot_path} {input.files}"


def read_filelist_pars_dsp_cal_channel(wildcards):
    """
    This function will read the filelist of the channels and return a list of dsp files one for each channel
    """
    label=f"all-{wildcards.experiment}-{wildcards.period}-{wildcards.run}-cal-channels"
    with checkpoints.gen_filelist.get(label=label, tier="dsp", extension="chan").output[0].open() as f:
        files = f.read().splitlines()
        return files 

rule build_pars_dsp:
    input:
        read_filelist_pars_dsp_cal_channel
    output:
        get_pattern_par_dsp(setup)
    group: "merge-dsp"
    script:
        "scripts/merge_channels.py"

def get_pars_dsp_file(wildcards):
    """
    This function will get the pars file for the run checking the pars_overwrite 
    """
    return ds.pars_catalog.get_par_file(setup, wildcards.timestamp, "dsp")

rule build_dsp:
    input:
        raw_file = get_pattern_tier_raw(setup),
        pars_file = get_pars_dsp_file
    params:
        timestamp = "{timestamp}",
        datatype = "{datatype}"
    output:
        get_pattern_tier_dsp(setup)
    group: "tier-dsp"
    resources:
        runtime=300
    shell:
        "{swenv} python3 {basedir}/scripts/build_dsp.py --configs {configs} --datatype {params.datatype} --timestamp {params.timestamp} --pars_file {input.pars_file} {input.raw_file} {output}"



def read_filelist_dsp_cal(wildcards):
    label = f"all-{wildcards.experiment}-{wildcards.period}-{wildcards.run}-cal"
    with checkpoints.gen_filelist.get(label=label, tier="dsp", extension="file").output[0].open() as f:
        files = f.read().splitlines()
        return files

#This rule builds the energy calibration using the calibration dsp files 
rule build_energy_calibration:
    input:
        files = read_filelist_dsp_cal
    output:
        ecal_file = temp(get_pattern_pars_tmp_channel(setup, "hit", "energy_cal")),
        plot_file = temp(get_pattern_plts_tmp_channel(setup, "hit","energy_cal"))
    group: "par-hit-ecal"
    resources:
        runtime=300
    shell:
        "{swenv} python3 {basedir}/scripts/pars_hit_ecal.py --configs {configs} --plot_path {output.plot_file} --save_path {output.ecal_file} {input.files}"


#This rule builds the a/e calibration using the calibration dsp files 
rule build_aoe_calibration:
    input:
        files = read_filelist_dsp_cal,
        ecal_file = get_pattern_pars_tmp_channel(setup, "hit", "energy_cal")
    output:
        hit_pars = temp(get_pattern_pars_tmp_channel(setup, "hit", "hit_pars")),
        plot_file = temp(get_pattern_plts_tmp_channel(setup, "hit","aoe_cal"))
    group: "par-hit-aoe"
    resources:
        runtime=300
    shell:
        "{swenv} python3 {basedir}/scripts/pars_hit_aoe.py  --configs {configs} --plot_file {output.plot_file} --hit_pars {output.hit_pars} --ecal_file {input.ecal_file} {input.files}"     


def read_filelist_pars_hit_cal_channel(wildcards):
    """
    This function will read the filelist of the channels and return a list of dsp files one for each channel
    """
    label=f"all-{wildcards.experiment}-{wildcards.period}-{wildcards.run}-cal-channels"
    with checkpoints.gen_filelist.get(label=label, tier="hit", extension="chan").output[0].open() as f:
        files = f.read().splitlines()
        return files 

def get_pars_hit_file(wildcards):
    """
    This function will get the pars file for the run checking the pars_overwrite 
    """
    return ds.pars_catalog.get_par_file(setup, wilcards.timestamp, "hit")

checkpoint build_pars_hit:
    input:
        read_filelist_pars_hit_cal_channel
    output:
        get_pattern_par_hit(setup)
    group: "merge-hit"
    script:
        "scripts/merge_channels.py"

rule build_hit:
    input:
        dsp_file = get_pattern_tier_dsp(setup),
        pars_file = get_pars_hit_file
    output:
        get_pattern_tier_hit(setup)
    group: "tier-hit"
    resources:
        runtime=300
    shell:
        "{swenv} python3 {basedir}/scripts/build_hit.py  --configs {configs} --pars_file {input.pars_file} {input.dsp_file} {output}"
