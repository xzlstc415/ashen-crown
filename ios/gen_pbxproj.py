#!/usr/bin/env python3
"""Writes AshenCrown.xcodeproj/project.pbxproj. Re-run only if files are added to the app target
(files inside AshenCrown/Web are picked up automatically: it is a folder reference)."""
import hashlib, pathlib
def oid(name): return hashlib.md5(name.encode()).hexdigest()[:24].upper()
SRC=['AppDelegate.swift','SceneDelegate.swift','GameViewController.swift','BundleSchemeHandler.swift']
RES=[('Assets.xcassets','folder.assetcatalog'),('Web','folder'),('PrivacyInfo.xcprivacy','text.xml')]
LANGS=['en','zh-Hans','ja']
P=oid('project');MAIN=oid('group.main');APPG=oid('group.app');PRODG=oid('group.products')
APP=oid('file.app');T=oid('target');SRCP=oid('phase.sources');RESP=oid('phase.resources');FWP=oid('phase.frameworks')
CLP=oid('cl.project');CLT=oid('cl.target');PD=oid('cfg.project.debug');PR=oid('cfg.project.release');TD=oid('cfg.target.debug');TR=oid('cfg.target.release')
INFO=oid('file.Info.plist');VG=oid('variant.InfoPlist.strings');VGB=oid('build.InfoPlist.strings')
o=[]
o.append('/* Begin PBXBuildFile section */')
for f in SRC:o.append(f'\t\t{oid("build."+f)} /* {f} in Sources */ = {{isa = PBXBuildFile; fileRef = {oid("file."+f)} /* {f} */; }};')
for f,_ in RES:o.append(f'\t\t{oid("build."+f)} /* {f} in Resources */ = {{isa = PBXBuildFile; fileRef = {oid("file."+f)} /* {f} */; }};')
o.append(f'\t\t{VGB} /* InfoPlist.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {VG} /* InfoPlist.strings */; }};')
o.append('/* End PBXBuildFile section */\n')
o.append('/* Begin PBXFileReference section */')
o.append(f'\t\t{APP} /* AshenCrown.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = AshenCrown.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
for f in SRC:o.append(f'\t\t{oid("file."+f)} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {f}; sourceTree = "<group>"; }};')
for f,t in RES:o.append(f'\t\t{oid("file."+f)} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = {t}; path = {f}; sourceTree = "<group>"; }};')
o.append(f'\t\t{INFO} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};')
for l in LANGS:o.append(f'\t\t{oid("file.strings."+l)} /* {l} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = {l}; path = {l}.lproj/InfoPlist.strings; sourceTree = "<group>"; }};')
o.append('/* End PBXFileReference section */\n')
o.append('/* Begin PBXFrameworksBuildPhase section */')
o.append(f'\t\t{FWP} /* Frameworks */ = {{\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};')
o.append('/* End PBXFrameworksBuildPhase section */\n')
o.append('/* Begin PBXGroup section */')
o.append(f'\t\t{MAIN} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{APPG} /* AshenCrown */,\n\t\t\t\t{PRODG} /* Products */,\n\t\t\t);\n\t\t\tsourceTree = "<group>";\n\t\t}};')
kids=[f'{oid("file."+f)} /* {f} */' for f in SRC]+[f'{oid("file."+f)} /* {f} */' for f,_ in RES]+[f'{VG} /* InfoPlist.strings */',f'{INFO} /* Info.plist */']
o.append(f'\t\t{APPG} /* AshenCrown */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n'+''.join(f'\t\t\t\t{k},\n' for k in kids)+'\t\t\t);\n\t\t\tpath = AshenCrown;\n\t\t\tsourceTree = "<group>";\n\t\t};')
o.append(f'\t\t{PRODG} /* Products */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{APP} /* AshenCrown.app */,\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = "<group>";\n\t\t}};')
o.append('/* End PBXGroup section */\n')
o.append('/* Begin PBXNativeTarget section */')
o.append(f'''\t\t{T} /* AshenCrown */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {CLT} /* Build configuration list for PBXNativeTarget "AshenCrown" */;
\t\t\tbuildPhases = (
\t\t\t\t{SRCP} /* Sources */,
\t\t\t\t{FWP} /* Frameworks */,
\t\t\t\t{RESP} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = AshenCrown;
\t\t\tproductName = AshenCrown;
\t\t\tproductReference = {APP} /* AshenCrown.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};''')
o.append('/* End PBXNativeTarget section */\n')
o.append('/* Begin PBXProject section */')
o.append(f'''\t\t{P} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{T} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {CLP} /* Build configuration list for PBXProject "AshenCrown" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t\t"zh-Hans",
\t\t\t\tja,
\t\t\t);
\t\t\tmainGroup = {MAIN};
\t\t\tproductRefGroup = {PRODG} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{T} /* AshenCrown */,
\t\t\t);
\t\t}};''')
o.append('/* End PBXProject section */\n')
o.append('/* Begin PBXResourcesBuildPhase section */')
rf=[f'{oid("build."+f)} /* {f} in Resources */' for f,_ in RES]+[f'{VGB} /* InfoPlist.strings in Resources */']
o.append(f'\t\t{RESP} /* Resources */ = {{\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n'+''.join(f'\t\t\t\t{k},\n' for k in rf)+'\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};')
o.append('/* End PBXResourcesBuildPhase section */\n')
o.append('/* Begin PBXSourcesBuildPhase section */')
sf=[f'{oid("build."+f)} /* {f} in Sources */' for f in SRC]
o.append(f'\t\t{SRCP} /* Sources */ = {{\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n'+''.join(f'\t\t\t\t{k},\n' for k in sf)+'\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};')
o.append('/* End PBXSourcesBuildPhase section */\n')
o.append('/* Begin PBXVariantGroup section */')
o.append(f'\t\t{VG} /* InfoPlist.strings */ = {{\n\t\t\tisa = PBXVariantGroup;\n\t\t\tchildren = (\n'+''.join(f'\t\t\t\t{oid("file.strings."+l)} /* {l} */,\n' for l in LANGS)+'\t\t\t);\n\t\t\tname = InfoPlist.strings;\n\t\t\tsourceTree = "<group>";\n\t\t};')
o.append('/* End PBXVariantGroup section */\n')
def cfg(i,name,settings):
    body=''.join(f'\t\t\t\t{k} = {v};\n' for k,v in settings.items())
    return f'\t\t{i} /* {name} */ = {{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {{\n{body}\t\t\t}};\n\t\t\tname = {name};\n\t\t}};'
common={'ALWAYS_SEARCH_USER_PATHS':'NO','CLANG_ENABLE_MODULES':'YES','CLANG_ENABLE_OBJC_ARC':'YES','COPY_PHASE_STRIP':'NO',
 'ENABLE_STRICT_OBJC_MSGSEND':'YES','GCC_C_LANGUAGE_STANDARD':'gnu17','IPHONEOS_DEPLOYMENT_TARGET':'15.0','SDKROOT':'iphoneos','SWIFT_VERSION':'5.0'}
pd=dict(common,**{'DEBUG_INFORMATION_FORMAT':'dwarf','ENABLE_TESTABILITY':'YES','GCC_OPTIMIZATION_LEVEL':'0','ONLY_ACTIVE_ARCH':'YES',
 'SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG','SWIFT_OPTIMIZATION_LEVEL':'"-Onone"'})
pr=dict(common,**{'DEBUG_INFORMATION_FORMAT':'"dwarf-with-dsym"','ENABLE_NS_ASSERTIONS':'NO','SWIFT_COMPILATION_MODE':'wholemodule','VALIDATE_PRODUCT':'YES'})
tgt={'ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','CODE_SIGN_STYLE':'Automatic','CURRENT_PROJECT_VERSION':'1','DEVELOPMENT_TEAM':'""',
 'GENERATE_INFOPLIST_FILE':'NO','INFOPLIST_FILE':'AshenCrown/Info.plist','LD_RUNPATH_SEARCH_PATHS':'(\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"@executable_path/Frameworks",\n\t\t\t\t)',
 'MARKETING_VERSION':'1.0','PRODUCT_BUNDLE_IDENTIFIER':'"com.hermes-eris.ashencrown"','PRODUCT_NAME':'"$(TARGET_NAME)"',
 'SUPPORTS_MACCATALYST':'NO','SWIFT_EMIT_LOC_STRINGS':'NO','TARGETED_DEVICE_FAMILY':'"1,2"'}
o.append('/* Begin XCBuildConfiguration section */')
o+= [cfg(PD,'Debug',pd),cfg(PR,'Release',pr),cfg(TD,'Debug',tgt),cfg(TR,'Release',tgt)]
o.append('/* End XCBuildConfiguration section */\n')
o.append('/* Begin XCConfigurationList section */')
for i,nm,d,r in [(CLP,'PBXProject "AshenCrown"',PD,PR),(CLT,'PBXNativeTarget "AshenCrown"',TD,TR)]:
    o.append(f'\t\t{i} /* Build configuration list for {nm} */ = {{\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t{d} /* Debug */,\n\t\t\t\t{r} /* Release */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}};')
o.append('/* End XCConfigurationList section */')
txt='// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 56;\n\tobjects = {\n\n'+'\n'.join(o)+f'\n\t}};\n\trootObject = {P} /* Project object */;\n}}\n'
out=pathlib.Path(__file__).parent/'AshenCrown.xcodeproj'/'project.pbxproj'
out.write_text(txt);print('wrote',out)
