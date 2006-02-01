# location of shuffle src
SHUFFLE_SRC_PREFIX	:= $(TOP_PREFIX)shuffle/

# location of shuffle build
SHUFFLE_BLD_PREFIX	:= $(BLD_PREFIX)shuffle/

# this file
SHUFFLE_MKF			:= $(SHUFFLE_SRC_PREFIX)files.mk

# main + sources + dpds
SHUFFLE_MAIN		:= Shuffle

#SHUFFLE_AG_MAIN_SRC	:= $(addprefix $(SHUFFLE_SRC_PREFIX),$(SHUFFLE_MAIN).ag)

SHUFFLE_HS_MAIN_SRC_HS					:= $(addprefix $(SHUFFLE_SRC_PREFIX),$(SHUFFLE_MAIN).hs)
SHUFFLE_HS_MAIN_DRV_HS					:= $(patsubst $(SHUFFLE_SRC_PREFIX)%.hs,$(SHUFFLE_BLD_PREFIX)%.hs,$(SHUFFLE_HS_MAIN_SRC_HS))
SHUFFLE_HS_DPDS_SRC_HS					:= $(patsubst %,$(SHUFFLE_SRC_PREFIX)%.hs,Common ChunkParser CDocCommon)
SHUFFLE_HS_DPDS_DRV_HS					:= $(patsubst $(SHUFFLE_SRC_PREFIX)%.hs,$(SHUFFLE_BLD_PREFIX)%.hs,$(SHUFFLE_HS_DPDS_SRC_HS))

SHUFFLE_AGMAIN_MAIN_SRC_AG				:= $(patsubst %,$(SHUFFLE_SRC_PREFIX)%.ag,MainAG)
SHUFFLE_AGMAIN_DPDS_SRC_AG				:= $(patsubst %,$(SHUFFLE_SRC_PREFIX)%.ag,CDocAbsSyn ChunkAbsSyn \
											)
$(patsubst $(SHUFFLE_SRC_PREFIX)%.ag,$(SHUFFLE_BLD_PREFIX)%.hs,$(SHUFFLE_AGMAIN_MAIN_SRC_AG)) \
										: $(SHUFFLE_AGMAIN_DPDS_SRC_AG)

SHUFFLE_AGCDOC_MAIN_SRC_AG				:= $(patsubst %,$(SHUFFLE_SRC_PREFIX)%.ag,CDoc)
SHUFFLE_AGCDOC_DPDS_SRC_AG				:= $(patsubst %,$(SHUFFLE_SRC_PREFIX)%.ag,CDocAbsSyn)
$(patsubst $(SHUFFLE_SRC_PREFIX)%.ag,$(SHUFFLE_BLD_PREFIX)%.hs,$(SHUFFLE_AGCDOC_MAIN_SRC_AG)) \
										: $(SHUFFLE_AGCDOC_DPDS_SRC_AG)

SHUFFLE_CDSUBS_MAIN_SRC_AG				:= $(patsubst %,$(SHUFFLE_SRC_PREFIX)%.ag,CDocSubst)
SHUFFLE_CDSUBS_DPDS_SRC_AG				:= $(patsubst %,$(SHUFFLE_SRC_PREFIX)%.ag,CDocAbsSyn CDocCommonAG)
$(patsubst $(SHUFFLE_SRC_PREFIX)%.ag,$(SHUFFLE_BLD_PREFIX)%.hs,$(SHUFFLE_CDSUBS_MAIN_SRC_AG)) \
										: $(SHUFFLE_CDSUBS_DPDS_SRC_AG)

SHUFFLE_CDINLN_MAIN_SRC_AG				:= $(patsubst %,$(SHUFFLE_SRC_PREFIX)%.ag,CDocInline)
SHUFFLE_CDINLN_DPDS_SRC_AG				:= $(patsubst %,$(SHUFFLE_SRC_PREFIX)%.ag,CDocAbsSyn)
$(patsubst $(SHUFFLE_SRC_PREFIX)%.ag,$(SHUFFLE_BLD_PREFIX)%.hs,$(SHUFFLE_CDINLN_MAIN_SRC_AG)) \
										: $(SHUFFLE_CDINLN_DPDS_SRC_AG)

SHUFFLE_AG_D_MAIN_SRC_AG				:= $(SHUFFLE_AGCDOC_MAIN_SRC_AG)
SHUFFLE_AG_S_MAIN_SRC_AG				:= $(SHUFFLE_CDSUBS_MAIN_SRC_AG) $(SHUFFLE_CDINLN_MAIN_SRC_AG)
SHUFFLE_AG_DS_MAIN_SRC_AG				:= $(SHUFFLE_AGMAIN_MAIN_SRC_AG)

SHUFFLE_AG_ALL_DPDS_SRC_AG				:= $(sort \
											$(SHUFFLE_AGMAIN_DPDS_SRC_AG) \
											$(SHUFFLE_CDSUBS_DPDS_SRC_AG) \
											$(SHUFFLE_CDINLN_DPDS_SRC_AG) \
											$(SHUFFLE_AGCDOC_DPDS_SRC_AG) \
											)

SHUFFLE_AG_ALL_MAIN_SRC_AG				:= $(SHUFFLE_AG_D_MAIN_SRC_AG) $(SHUFFLE_AG_S_MAIN_SRC_AG) $(SHUFFLE_AG_DS_MAIN_SRC_AG)



# all src
SHUFFLE_ALL_SRC							:= $(SHUFFLE_AG_ALL_MAIN_SRC_AG) $(SHUFFLE_AG_ALL_DPDS_SRC_AG) $(SHUFFLE_HS_MAIN_SRC_HS) $(SHUFFLE_HS_DPDS_SRC_HS)

# derived
SHUFFLE_AG_D_MAIN_DRV_HS				:= $(patsubst $(SHUFFLE_SRC_PREFIX)%.ag,$(SHUFFLE_BLD_PREFIX)%.hs,$(SHUFFLE_AG_D_MAIN_SRC_AG))
SHUFFLE_AG_S_MAIN_DRV_HS				:= $(patsubst $(SHUFFLE_SRC_PREFIX)%.ag,$(SHUFFLE_BLD_PREFIX)%.hs,$(SHUFFLE_AG_S_MAIN_SRC_AG))
SHUFFLE_AG_DS_MAIN_DRV_HS				:= $(patsubst $(SHUFFLE_SRC_PREFIX)%.ag,$(SHUFFLE_BLD_PREFIX)%.hs,$(SHUFFLE_AG_DS_MAIN_SRC_AG))
SHUFFLE_AG_ALL_MAIN_DRV_HS				:= $(SHUFFLE_AG_D_MAIN_DRV_HS) $(SHUFFLE_AG_S_MAIN_DRV_HS) $(SHUFFLE_AG_DS_MAIN_DRV_HS)

SHUFFLE_HS_ALL_DRV_HS					:= $(SHUFFLE_HS_MAIN_DRV_HS) $(SHUFFLE_HS_DPDS_DRV_HS)

# binary/executable
SHUFFLE_BLD_EXEC	:= $(BIN_PREFIX)shuffle
SHUFFLE				:= $(SHUFFLE_BLD_EXEC)

# distribution
SHUFFLE_DIST_FILES			:= $(SHUFFLE_ALL_SRC) $(SHUFFLE_MKF)

# make rules
$(SHUFFLE_BLD_EXEC): $(SHUFFLE_AG_ALL_MAIN_DRV_HS) $(SHUFFLE_HS_ALL_DRV_HS) $(LIB_SRC_HS)
	$(GHC) --make $(GHC_OPTS) $(GHC_OPTS_OPTIM) -i$(LIB_SRC_PREFIX) -i$(SHUFFLE_BLD_PREFIX) $(SHUFFLE_BLD_PREFIX)$(SHUFFLE_MAIN).hs -o $@
	strip $@

$(SHUFFLE_AG_D_MAIN_DRV_HS): $(SHUFFLE_BLD_PREFIX)%.hs: $(SHUFFLE_SRC_PREFIX)%.ag
	mkdir -p $(@D) ; \
	$(AGC) --module=$(*F) -dr -P$(SHUFFLE_SRC_PREFIX) -o $@ $<

$(SHUFFLE_AG_S_MAIN_DRV_HS): $(SHUFFLE_BLD_PREFIX)%.hs: $(SHUFFLE_SRC_PREFIX)%.ag
	mkdir -p $(@D) ; \
	$(AGC) -cfspr -P$(SHUFFLE_SRC_PREFIX) -o $@ $<

$(SHUFFLE_AG_DS_MAIN_DRV_HS): $(SHUFFLE_BLD_PREFIX)%.hs: $(SHUFFLE_SRC_PREFIX)%.ag
	mkdir -p $(@D) ; \
	$(AGC) --module=$(*F) -dcfspr -P$(SHUFFLE_SRC_PREFIX) -o $@ $<

$(SHUFFLE_HS_ALL_DRV_HS): $(SHUFFLE_BLD_PREFIX)%.hs: $(SHUFFLE_SRC_PREFIX)%.hs
	mkdir -p $(@D) ; \
	cp $< $@

