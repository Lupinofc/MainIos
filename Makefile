# =============================================================================
# Makefile — ThreeOneOSFive (3105) iOS App
# Compila Swift + ObjC/C usando o toolchain do Theos no Ubuntu/Linux
# Gera: packages/3105-unsigned.ipa
# =============================================================================

# ---------------------------------------------------------------------------
# Toolchain
# ---------------------------------------------------------------------------
THEOS          ?= $(HOME)/theos
SDK_VERSION    ?= 14.5
TARGET_ARCH    ?= arm64
MIN_IOS        ?= 16.0

SDK            := $(THEOS)/sdks/iPhoneOS$(SDK_VERSION).sdk
SYSROOT        := $(SDK)

# Compiladores do toolchain do Theos
SWIFTC         := $(THEOS)/toolchain/swift/bin/swiftc
CLANG          := $(THEOS)/toolchain/linux/iphone/bin/clang
AR             := $(THEOS)/toolchain/linux/iphone/bin/ar
LIPO           := $(THEOS)/toolchain/linux/iphone/bin/lipo
INSTALL_NAME   := $(THEOS)/toolchain/linux/iphone/bin/install_name_tool
CODESIGN       := ldid

# ---------------------------------------------------------------------------
# Identificação do app
# ---------------------------------------------------------------------------
APP_NAME       := 3105
BUNDLE_ID      := com.apple.mobile.MobileHouseArrest
APP_DIR        := $(APP_NAME).app

# ---------------------------------------------------------------------------
# Diretórios do projeto
# ---------------------------------------------------------------------------
SRC_ROOT       := ThreeOneOSFive
EXPLOIT_DIR    := $(SRC_ROOT)/exploit
KEXPLOIT_DIR   := $(SRC_ROOT)/kexploit
HELPERS_DIR    := $(SRC_ROOT)/helpers
VIEWS_DIR      := $(SRC_ROOT)/views

BUILD_DIR      := .theos/build
OBJ_DIR        := $(BUILD_DIR)/obj
PRODUCT_DIR    := $(BUILD_DIR)/$(APP_DIR)
IPA_STAGING    := $(BUILD_DIR)/ipa_staging

# ---------------------------------------------------------------------------
# Flags comuns
# ---------------------------------------------------------------------------
ARCH_FLAGS     := -arch $(TARGET_ARCH)
DEPLOY_FLAGS   := -miphoneos-version-min=$(MIN_IOS)
SYSROOT_FLAGS  := -isysroot $(SYSROOT)

COMMON_FLAGS   := $(ARCH_FLAGS) $(DEPLOY_FLAGS) $(SYSROOT_FLAGS) \
                  -target $(TARGET_ARCH)-apple-ios$(MIN_IOS) \
                  -Os

# ---------------------------------------------------------------------------
# Flags ObjC / C
# ---------------------------------------------------------------------------
OBJC_FLAGS     := $(COMMON_FLAGS) \
                  -fobjc-arc \
                  -fmodules \
                  -I$(SRC_ROOT) \
                  -I$(EXPLOIT_DIR) \
                  -I$(KEXPLOIT_DIR) \
                  -I$(HELPERS_DIR) \
                  -F$(SYSROOT)/System/Library/Frameworks \
                  -DTHEOS_BUILD=1

# ---------------------------------------------------------------------------
# Flags Swift
# ---------------------------------------------------------------------------
SWIFT_MODULE   := ThreeOneOSFive

SWIFT_FLAGS    := \
                  -sdk $(SYSROOT) \
                  -target $(TARGET_ARCH)-apple-ios$(MIN_IOS) \
                  -module-name $(SWIFT_MODULE) \
                  -import-objc-header $(SRC_ROOT)/ThreeOneOSFive-Bridging-Header.h \
                  -O \
                  -whole-module-optimization \
                  -Xfrontend -enable-objc-interop \
                  -Xcc -I$(SRC_ROOT) \
                  -Xcc -I$(EXPLOIT_DIR) \
                  -Xcc -I$(KEXPLOIT_DIR) \
                  -Xcc -I$(HELPERS_DIR) \
                  -Xcc -fmodules \
                  -Xcc -DTHEOS_BUILD=1

# Frameworks necessários para linker
FRAMEWORKS     := -framework UIKit \
                  -framework Foundation \
                  -framework SwiftUI \
                  -framework Combine \
                  -framework CoreFoundation \
                  -framework CoreGraphics \
                  -framework PhotosUI \
                  -framework Photos \
                  -framework UniformTypeIdentifiers \
                  -framework MobileCoreServices \
                  -framework Security \
                  -framework Darwin

LIBS           := -lc++ -lc -lobjc -lswiftCore -lswiftFoundation \
                  -lswiftSwiftOnoneSupport

LINKER_FLAGS   := $(ARCH_FLAGS) $(DEPLOY_FLAGS) $(SYSROOT_FLAGS) \
                  -target $(TARGET_ARCH)-apple-ios$(MIN_IOS) \
                  -L$(SYSROOT)/usr/lib \
                  -L$(THEOS)/toolchain/swift/lib/swift/iphoneos \
                  -Wl,-rpath,@executable_path/Frameworks \
                  $(FRAMEWORKS) \
                  $(LIBS)

# ---------------------------------------------------------------------------
# Fontes ObjC / C
# ---------------------------------------------------------------------------
OBJC_SOURCES   := \
    $(EXPLOIT_DIR)/bad_query.c \
    $(EXPLOIT_DIR)/mcm_bridge.m \
    $(EXPLOIT_DIR)/wallpaper_zip.c \
    $(KEXPLOIT_DIR)/kexploit_opa334.m \
    $(KEXPLOIT_DIR)/offsets.m \
    $(KEXPLOIT_DIR)/krw.m \
    $(KEXPLOIT_DIR)/kutils.m \
    $(KEXPLOIT_DIR)/vnode.m \
    $(KEXPLOIT_DIR)/sandbox_escape.m \
    $(HELPERS_DIR)/AppIconHelper.m \
    $(HELPERS_DIR)/AntiDetection.m \
    $(HELPERS_DIR)/DisplayIdentity.m

# ---------------------------------------------------------------------------
# Fontes Swift (ordem importa: modelos antes de views)
# ---------------------------------------------------------------------------
SWIFT_SOURCES  := \
    $(SRC_ROOT)/App.swift \
    $(SRC_ROOT)/ContentView.swift \
    $(SRC_ROOT)/KeyLoginView.swift \
    $(HELPERS_DIR)/Utils.swift \
    $(HELPERS_DIR)/SBX.swift \
    $(HELPERS_DIR)/MG.swift \
    $(HELPERS_DIR)/Localization.swift \
    $(HELPERS_DIR)/AppTabNavigationState.swift \
    $(HELPERS_DIR)/SupportPolicy.swift \
    $(HELPERS_DIR)/DisplayIdentityAttribution.swift \
    $(HELPERS_DIR)/KernelExploit.swift \
    $(HELPERS_DIR)/KeyAuthService.swift \
    $(HELPERS_DIR)/ContainerIdentityResolver.swift \
    $(HELPERS_DIR)/ContainerStore.swift \
    $(HELPERS_DIR)/ContainerBrowserLogic.swift \
    $(HELPERS_DIR)/FileBrowserMetadata.swift \
    $(HELPERS_DIR)/FileManagerService.swift \
    $(HELPERS_DIR)/FileReplacementService.swift \
    $(HELPERS_DIR)/FileOperationCoordinator.swift \
    $(HELPERS_DIR)/SecureZIPArchive.swift \
    $(HELPERS_DIR)/PatchProjectModels.swift \
    $(HELPERS_DIR)/PatchPackageCodec.swift \
    $(HELPERS_DIR)/PatchKeyStore.swift \
    $(HELPERS_DIR)/PatchTransaction.swift \
    $(HELPERS_DIR)/DevicePatchService.swift \
    $(HELPERS_DIR)/PatchProjectLibrary.swift \
    $(HELPERS_DIR)/PatchProjectStore.swift \
    $(HELPERS_DIR)/PatchDraftService.swift \
    $(HELPERS_DIR)/PatchDraftCoordinator.swift \
    $(HELPERS_DIR)/PatchWorkspaceService.swift \
    $(HELPERS_DIR)/LimitedCleanerService.swift \
    $(HELPERS_DIR)/CleanerCatalog.swift \
    $(HELPERS_DIR)/WallpaperLabModels.swift \
    $(HELPERS_DIR)/WallpaperLabService.swift \
    $(HELPERS_DIR)/WallpaperInstaller.swift \
    $(HELPERS_DIR)/PackageRepositoryModels.swift \
    $(HELPERS_DIR)/PackageRepositoryStore.swift \
    $(HELPERS_DIR)/RepositoryPresentationSupport.swift \
    $(VIEWS_DIR)/DesignSystem.swift \
    $(VIEWS_DIR)/LogView.swift \
    $(VIEWS_DIR)/SettingsView.swift \
    $(VIEWS_DIR)/FileBrowserView.swift \
    $(VIEWS_DIR)/FilesTabControls.swift \
    $(VIEWS_DIR)/FilesTabSwitcherView.swift \
    $(VIEWS_DIR)/AppDataBrowserView.swift \
    $(VIEWS_DIR)/FolderPatchSelectionView.swift \
    $(VIEWS_DIR)/PatchProjectsView.swift \
    $(VIEWS_DIR)/PatchProjectEditorView.swift \
    $(VIEWS_DIR)/CleanerView.swift \
    $(VIEWS_DIR)/WallpaperLabView.swift \
    $(VIEWS_DIR)/RepositoryHomeView.swift \
    $(VIEWS_DIR)/RepositoryMarketplaceView.swift \
    $(VIEWS_DIR)/RepositorySourcesView.swift \
    $(VIEWS_DIR)/OnboardingView.swift

# ---------------------------------------------------------------------------
# Objetos compilados
# ---------------------------------------------------------------------------
OBJC_OBJECTS   := $(patsubst %.c,$(OBJ_DIR)/%.o,$(patsubst %.m,$(OBJ_DIR)/%.o,$(OBJC_SOURCES)))
SWIFT_OBJECT   := $(OBJ_DIR)/swift_module.o

# ---------------------------------------------------------------------------
# Targets principais
# ---------------------------------------------------------------------------
.PHONY: all clean package ipa setup

all: setup $(PRODUCT_DIR)/$(APP_NAME)

# Cria diretórios necessários
setup:
	@mkdir -p $(OBJ_DIR)/$(EXPLOIT_DIR) \
	          $(OBJ_DIR)/$(KEXPLOIT_DIR) \
	          $(OBJ_DIR)/$(HELPERS_DIR) \
	          $(PRODUCT_DIR)

# ---------------------------------------------------------------------------
# Compilar ObjC / C → .o individuais
# ---------------------------------------------------------------------------
$(OBJ_DIR)/%.o: %.m
	@echo "[CC]  $<"
	@mkdir -p $(dir $@)
	$(CLANG) $(OBJC_FLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: %.c
	@echo "[CC]  $<"
	@mkdir -p $(dir $@)
	$(CLANG) $(OBJC_FLAGS) -c $< -o $@

# ---------------------------------------------------------------------------
# Compilar todos os Swift em um único módulo → .o
# ---------------------------------------------------------------------------
$(SWIFT_OBJECT): $(SWIFT_SOURCES)
	@echo "[SWIFTC] Compilando módulo Swift..."
	@mkdir -p $(dir $@)
	$(SWIFTC) $(SWIFT_FLAGS) \
	    -emit-object \
	    -o $@ \
	    $(SWIFT_SOURCES)

# ---------------------------------------------------------------------------
# Linkar tudo → binário final
# ---------------------------------------------------------------------------
$(PRODUCT_DIR)/$(APP_NAME): $(OBJC_OBJECTS) $(SWIFT_OBJECT)
	@echo "[LD]  Linkando $@..."
	$(CLANG) $(LINKER_FLAGS) \
	    $(OBJC_OBJECTS) $(SWIFT_OBJECT) \
	    -o $@

# ---------------------------------------------------------------------------
# Montar o .app bundle
# ---------------------------------------------------------------------------
bundle: $(PRODUCT_DIR)/$(APP_NAME)
	@echo "[BUNDLE] Montando $(APP_DIR)..."
	# Info.plist — substitui variáveis do Xcode
	sed \
	    -e 's/$$(EXECUTABLE_NAME)/$(APP_NAME)/g' \
	    -e 's/$$(PRODUCT_BUNDLE_IDENTIFIER)/$(BUNDLE_ID)/g' \
	    $(SRC_ROOT)/Info.plist > $(PRODUCT_DIR)/Info.plist
	# Assets (ícone)
	cp -R $(SRC_ROOT)/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png \
	    $(PRODUCT_DIR)/AppIcon.png 2>/dev/null || true
	# Strings de localização
	@for lproj in $(SRC_ROOT)/*.lproj; do \
	    lang=$$(basename $$lproj); \
	    mkdir -p $(PRODUCT_DIR)/$$lang; \
	    cp $$lproj/*.strings $(PRODUCT_DIR)/$$lang/ 2>/dev/null || true; \
	done
	@echo "[BUNDLE] OK — $(PRODUCT_DIR)"

# ---------------------------------------------------------------------------
# Assinar com ldid (fake-sign, compatível com jailbreak/sideload)
# ---------------------------------------------------------------------------
sign: bundle
	@echo "[SIGN] Assinando com ldid..."
	$(CODESIGN) -S$(PWD)/entitlements.plist $(PRODUCT_DIR)/$(APP_NAME)
	@echo "[SIGN] OK"

# ---------------------------------------------------------------------------
# Empacotar IPA
# ---------------------------------------------------------------------------
ipa: sign
	@echo "[IPA] Empacotando..."
	@mkdir -p packages $(IPA_STAGING)/Payload
	@rm -rf $(IPA_STAGING)/Payload/$(APP_DIR)
	@cp -R $(PRODUCT_DIR) $(IPA_STAGING)/Payload/$(APP_DIR)
	@cd $(IPA_STAGING) && zip -qry $(PWD)/packages/$(APP_NAME)-unsigned.ipa Payload
	@echo "[IPA] Gerada: packages/$(APP_NAME)-unsigned.ipa"

package: ipa

# ---------------------------------------------------------------------------
# Limpar
# ---------------------------------------------------------------------------
clean:
	@echo "[CLEAN] Removendo build..."
	@rm -rf .theos packages
	@echo "[CLEAN] OK"
