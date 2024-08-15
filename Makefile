# Building and testing Apptainer images to support WideVariant workflow
#
# The primary targets in this file are:
#
# all             Build and test all images
# build           Build the images
# test            Test the images
# clean           Clean up generated images and temporary files
#
# Image-specific test targets:
# test_widevariant_image
# test_srst2_image
#
# Variables:
# apptainer_tmpdir  Parent directory for temporary Apptainer file directories (default: $(HOME)/tmp/apptainer-build)
# apptainer_mod		Module with apptainer executable
# img_dir           Directory to store container images (default: $(GROUP_HOME)/containers)
#

QUIET = @

C_BUILD := apptainer build --fakeroot
C_RUN := apptainer exec
CMD := command -v
LOAD := module load
MKDIR := mkdir -p
PURGE := module purge
QGREP := grep -q
RM := rm -f

apptainer_tmpdir ?= $(HOME)/tmp/apptainer-build
apptainer_mod ?= apptainer/1.3.2
img_dir ?= $(GROUP_HOME)/containers

wdvar_img := $(img_dir)/widevariant.sif
srst2_img := $(img_dir)/srst2.sif

# $(call TEST_EXEC, command, image, arguments, success_string)
# 
# Run a command to test an executable inside the image by checking for success string in output.
define TEST_EXEC
	$(QUIET) echo -n 'Looking for $(1)... ' && \
	$(PURGE) && \
	$(LOAD) $(apptainer_mod) && \
	($(C_RUN) $(2) $(1) $(3) 2>&1 | $(QGREP) $(4)) && \
	echo 'Success!'
endef

.PHONY: all build test clean

all: build test

build: setup $(wdvar_img) $(srst2_img)

setup: check_module mk_tmpdir

check_module:
	$(QUIET) echo "Checking apptainer module..."
	$(QUIET) $(PURGE) && \
	$(LOAD) $(apptainer_mod) && \
	(apptainer --version 2>&1 | $(QGREP) 'apptainer version') && \
	$(PURGE)

mk_tmpdir:
	$(MKDIR) $(apptainer_tmpdir)

%.sif:
	$(PURGE) && \
	$(LOAD) $(apptainer_mod) && \
	export APPTAINER_TMPDIR=$(apptainer_tmpdir)/$(basename $(notdir $*.def)) && \
	$(MKDIR) $$APPTAINER_TMPDIR && \
	$(C_BUILD) --notest $@ defs/$(notdir $*.def) && \
	$(PURGE)

# NOTE: Using tests here, since apptainer's built-in %test is hitting stale NFS handles

test: test_widevariant_image test_srst2_image
	$(QUIET) echo 'Testing of widevariant image at $(wdvar_img) is finished!'
	$(QUIET) echo 'Testing of srst2 image at $(srst2_img) is finished!'
	$(QUIET) rm -rf spades_test && module purge

.PHONY: test_widevariant_image test_srst2_image

test_widevariant_image: test_bowtie2_latest test_bracken test_cutadapt test_kraken2 test_krakenuniq test_picard test_samtools_latest test_sickle test_smk_wrappers test_spades test_widevariant_utils

test_bowtie2_latest:
	$(call TEST_EXEC,bowtie2,$(wdvar_img),--version,'/opt/conda/bin/bowtie2')

test_bracken:
	$(call TEST_EXEC,bracken,$(wdvar_img),-v,'Bracken v')

test_cutadapt:
	$(call TEST_EXEC,cutadapt,$(wdvar_img),--version,'[4-6]\.[0-9]')

test_kraken2:
	$(call TEST_EXEC,kraken2,$(wdvar_img),--version,'Kraken version')
	$(call TEST_EXEC,kraken2-build,$(wdvar_img),--version,'Kraken version')
	$(call TEST_EXEC,kraken2-inspect,$(wdvar_img),--version,'Kraken version')

test_krakenuniq:
	$(call TEST_EXEC,krakenuniq,$(wdvar_img),--version,'KrakenUniq version')

test_picard:
	$(call TEST_EXEC,picard MarkDuplicates,$(wdvar_img),-h,'USAGE: MarkDuplicates')

test_samtools_latest:
	$(call TEST_EXEC,samtools,$(wdvar_img),--version,'Samtools compilation')
	$(call TEST_EXEC,tabix,$(wdvar_img),--version,'tabix (htslib)')
	$(call TEST_EXEC,bcftools,$(wdvar_img),--version,'bcftools 1.')

test_sickle:
	$(call TEST_EXEC,sickle,$(wdvar_img),--version,'sickle version')

test_smk_wrappers:
	$(QUIET) echo -n 'Looking for snakemake_wrapper_utils... ' && \
	($(C_RUN) $(wdvar_img) python -c "from snakemake_wrapper_utils import __version__; print('swu')" 2>&1 | $(QGREP) 'swu') && \
	echo 'Success!'

test_spades:
	$(call TEST_EXEC,spades.py,$(wdvar_img),-h,'SPAdes genome assembler')
	$(QUIET) echo -n 'Running SPAdes tests... ' && \
	($(C_RUN) $(wdvar_img) spades.py --test 2>&1 | $(QGREP) 'SPAdes pipeline finished') && \
	echo 'Succes!'

test_widevariant_utils:
	$(call TEST_EXEC,widevariant_utils,$(wdvar_img),--version,'widevariant_utils')

test_srst2_image: test_bowtie2_legacy test_samtools_legacy test_srst2

test_bowtie2_legacy:
	$(call TEST_EXEC,bowtie2,$(srst2_img),--version,'/bin/bowtie2-align version 2.1.0')

test_samtools_legacy:
	$(QUIET) echo -n 'Checking legacy samtools<=0.1.18... ' && \
	($(C_RUN) $(srst2_img) samtools 2>&1 | grep -oP 'Version: \K[\d.]+' | awk '{if ($$1 <= 0.1.18) exit 0; else exit 1}') && \
	echo 'Succes!'

test_srst2:
	$(call TEST_EXEC,srst2,$(srst2_img),--version -h,'srst2')
	$(call TEST_EXEC,getmlst.py,$(srst2_img),-h,'Download MLST datasets')
	$(call TEST_EXEC,slurm_srst2.py,$(srst2_img),-h,'Submit SRST2 jobs')

clean:
	$(QUIET) $(RM) $(wdvar_img)
	$(QUIET) $(RM) $(srst2_img)