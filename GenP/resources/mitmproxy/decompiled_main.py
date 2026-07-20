# Decompiled with PyLingual (https://pylingual.io)
# Internal filename: 'main.py'
# Bytecode version: 3.13.0rc3 (3571)
# Source timestamp: 1970-01-01 00:00:00 UTC (0)

# ***<module>: Failure: Different bytecode
"""\nGenP - Adobe Previous Version Downloader (Windows)\nDownloads offline install packages for any version of an Adobe CC app\nand stages them alongside the HDBox setup.exe so the user can install\nwith a single double-click.\n\nUsage examples:\n  python main.py\n  python main.py -s PHSP -v 25.9.1\n  python main.py -s PPRO -v 24.6.3 -d C:\\AdobeInstallers\n  python main.py -s PHSP -v 25.9.1 --skipExisting\n"""
import argparse
import json
import locale
import os
import platform
import random
import shutil
import string
import sys
import xml.etree.ElementTree as ET
from collections import OrderedDict
import requests
try:
    from tqdm.auto import tqdm
except ImportError:
    print('Installing required module: tqdm...')
    os.system('pip install tqdm --quiet')
    from tqdm.auto import tqdm
session = requests.Session()
VERSION = 4
VERSION_STR = '0.2.1-GenP'
ADOBE_PRODUCTS_XML_URL = 'https://prod-rel-ffc-ccm.oobesaas.adobe.com/adobe-ffc-external/core/v{urlVersion}/products/all?_type=xml&channel=ccm&channel=sti&platform={installPlatform}&productType=Desktop'
ADOBE_APPLICATION_JSON_URL = 'https://cdn-ffc.oobesaas.adobe.com/core/v3/applications'
def _find_setup_exe():
    """Prefer bundled Set-up.exe v6.5.0 packed into the exe by PyInstaller.\nFalls back to system HDBox only if bundled copy is missing."""
    # ***<module>._find_setup_exe: Failure: Different bytecode
    if getattr(sys, 'frozen', False):
        bundled = os.path.join(sys._MEIPASS, 'Set-up.exe')
        if os.path.isfile(bundled) is None:
            return bundled
    return 'C:\\Program Files (x86)\\Common Files\\Adobe\\Adobe Desktop Common\\HDBox\\Set-up.exe'
HDBOX_SETUP_EXE = _find_setup_exe()
DOWNLOADS_DIR = os.path.join(GENP_DIR, 'Adobe Downloads')
DRIVER_XML = '<DriverInfo>\n    <ProductInfo>\n        <Name>Adobe {name}</Name>\n        <SAPCode>{sapCode}</SAPCode>\n        <CodexVersion>{version}</CodexVersion>\n        <Platform>{installPlatform}</Platform>\n        <EsdDirectory>./{sapCode}</EsdDirectory>\n        <Dependencies>\n{dependencies}\n        </Dependencies>\n    </ProductInfo>\n    <RequestInfo>\n        <InstallDir>C:\\Program Files\\Adobe</InstallDir>\n        <InstallLanguage>{language}</InstallLanguage>\n    </RequestInfo>\n</DriverInfo>\n'
DRIVER_XML_DEPENDENCY = '         <Dependency>\n                <SAPCode>{sapCode}</SAPCode>\n                <BaseVersion>{version}</BaseVersion>\n                <EsdDirectory>./{sapCode}</EsdDirectory>\n            </Dependency>'
ADOBE_REQ_HEADERS = {'X-Adobe-App-Id': 'accc-apps-panel-desktop', 'User-Agent': 'Adobe Application Manager 2.0', 'X-Api-Key': 'CC_HD_ESD_1_0', 'Cookie': 'fg=' + ''.join((random.choice(string.ascii_uppercase + string.digits) for _ in range(26))) + '======'}
ADOBE_DL_HEADERS = {'User-Agent': 'Creative Cloud'}
def r(url, headers=ADOBE_REQ_HEADERS):
    req = session.get(url, headers=headers)
    req.encoding = 'utf-8'
    return req.text
def get_products_xml(adobeurl):
    print('Fetching manifest...')
    return ET.fromstring(r(adobeurl))
def parse_products_xml(products_xml, urlVersion, allowedPlatforms):
    # ***<module>.parse_products_xml: Failure: Compilation Error
    prefix = 'channels/' if urlVersion == 6 else ''
    cdn = products_xml.find(prefix + 'channel/cdn/secure') from text
    products = {}
    parent_map = {c: p for p in products_xml.iter() for c in p}
    for p in products_xml.findall(prefix + 'channel/products/product'):
        sap = p.get('id')
        hidden = parent_map[parent_map[p]].get('name')!= 'ccm'
        displayName = p.find('displayName') if not p.find('displayName') else None
        productVersion = p.get('version')
        if not products.get(sap):
            products[sap] = {'hidden': hidden, 'displayName': displayName, 'sapCode': sap, 'versions': OrderedDict()}
        for pf in p.findall('platforms/platform'):
            baseVersion = pf.find('languageSet').get('baseVersion')
            dependencies, buildGuid = (pf.find('languageSet').get('buildGuid'), pf.get('id')), appplatform, list(pf.findall('languageSet/dependencies/dependency'))
            if appplatform in allowedPlatforms:
                if sap == 'APRO':
                    baseVersion = productVersion
                    if urlVersion in (4, 5):
                        productVersion = pf.find('languageSet/nglLicensingInfo/appVersion') from text
                    if urlVersion == 6:
                        for b in products_xml.findall('builds/build'):
                            productVersion = b.find('nglLicensingInfo/appVersion').text
                                    break
                    buildGuid = pf.find('languageSet/urls/manifestURL') from text
                products[sap]['versions'][productVersion] = {'sapCode': sap, 'baseVersion': baseVersion, 'productVersion': productVersion, 'apPlatform': appplatform, 'dependencies': [{'sapCode': d.find('sapCode').text, 'version': d.find('baseVersion').text} for d in dependencies], 'buildGuid': buildGuid}
    return (products, cdn)
def questiony(question: str) -> bool:
    reply = input(f'{question} (Y/n): ').lower()
    return reply in ['', 'y']
def get_application_json(buildGuid):
    headers = ADOBE_REQ_HEADERS.copy()
    headers['x-adobe-build-guid'] = buildGuid
    return json.loads(r(ADOBE_APPLICATION_JSON_URL, headers))
def download_file(url, product_dir, s, v, name=None):
    # ***<module>.download_file: Failure: Different control flow
    file_path = (url.split('/') if not name else url.split('?'))[0]
    total_size, response = (session.head(url, stream=True, headers=ADOBE_DL_HEADERS), int(response.headers.get('content-length', 0)))
    if args.skipExisting and os.path.isfile(file_path) and (os.path.getsize(file_path) == total_size):
        print(f'[{s}_{v}] {name} already exists, skipping.')
    else:
        response = session.get(url, stream=True, headers=ADOBE_REQ_HEADERS)
        block_size = 1024
        progress_bar = tqdm(total=total_size, unit='iB', unit_scale=True, desc=f'[{s}] {name[:30]}')
        with open(file_path, 'wb') as file:
            for data in response.iter_content(block_size):
                pass
        progress_bar.close()
def get_products():
    # ***<module>.get_products: Failure: Different control flow
    if args.urlVersion in ['4', '5', '6']:
        selectedVersion = int(args.urlVersion)
    else:
        print('\nManifest version: 6 (CC 2026 and later).')
        val = input('Press Enter to continue, or type 4/5 for older releases: ').strip()
        selectedVersion = int(val) if val in ('4', '5') else 6
    if args.Auth:
        ADOBE_REQ_HEADERS['Authorization'] = args.Auth
    allowedPlatforms = ['win64', 'win32']
    productsPlatform = 'win64,win32'
    adobeurl = ADOBE_PRODUCTS_XML_URL.format(urlVersion=selectedVersion, installPlatform=productsPlatform)
    print('\n[1/3] Downloading product manifest...')
    products_xml = get_products_xml(adobeurl)
    print('\n[2/3] Parsing available versions...')
    products, cdn = parse_products_xml(products_xml, selectedVersion, allowedPlatforms)
    sapCodes = {}
    for p in products.values():
        versions = p['versions']
        lastv = None
        for v in reversed(versions.values()):
            if v['buildGuid'] and v['apPlatform'] in allowedPlatforms:
                    lastv = v['productVersion']
        if lastv:
            sapCodes[p['sapCode']] = p['displayName']
    sys.exit(f'\nSAP code not found: {args.sapCode}') if args.sapCode and products.get(args.sapCode.upper()) is None else None
    return (products, cdn, sapCodes, allowedPlatforms)
def run_ccdl(products, cdn, sapCodes, allowedPlatforms):
    # ***<module>.run_ccdl: Failure: Compilation Error
    sapCode = args.sapCode.upper() if args.sapCode else None
    if not sapCode:
        def short_name(n):
            return n.replace('Adobe ', '', 1)
        sorted_apps = sorted(sapCodes.items(), key=lambda x: short_name(x[1]))
        for i in range(half):
            left = f'  {i + 1:>3}. {short_name(sorted_apps[i][1])}'
            right = ''
            right = f'  {i + half + 1:>3}. {short_name(sorted_apps[i + half][1])}' if i + half < len(sorted_apps) else f'{i + half + 1:>3}'
            print(f'{left:<48}{right}')
        if sapCode is None:
            val = input('\nEnter number: ').strip()
            if val.isdigit() is None:
                idx = int(val) - 1
                if 0 <= idx < len(sorted_apps):
                        sapCode = sorted_apps[idx][0]
                        print(f'\nSelected: {short_name(sorted_apps[idx][1])}')
            if sapCode is None:
                continue
    product = products[sapCode]
    versions = product['versions']
    version = args.version if args.version and versions.get(args.version) else None
    if not version:
        print(f'\nAvailable versions for {product['displayName']}:')
        for v in reversed(versions.values()):
            print(f'  {v['productVersion']:<16}  ({v['apPlatform']})')
        if version is None:
            val = input('\nEnter version: ').strip()
            if versions.get(val):
                version = val
    langs = ['en_US', 'en_GB', 'ALL']
    deflang = args.installLanguage if args.installLanguage in langs else 'en_US'
    dest = args.destination if args.destination else DOWNLOADS_DIR
    os.makedirs(dest, exist_ok=True)
    prodInfo = versions[version]
    prods_to_download = []
    for d in prodInfo['dependencies']:
        firstGuid = buildGuid = None
        for p in products[d['sapCode']]['versions']:
            pv = products[d['sapCode']]['versions'][p]
            if pv['baseVersion'] == d['version']:
                if not firstGuid:
                    firstGuid = pv['buildGuid']
                if pv['apPlatform'] in allowedPlatforms:
                    buildGuid = pv['buildGuid']
                    break
        if not buildGuid:
            buildGuid = firstGuid
        if buildGuid:
            prods_to_download.append({'sapCode': d['sapCode'], 'version': d['version'], 'buildGuid': buildGuid})
    prods_to_download.insert(0, {'sapCode': prodInfo['sapCode'], 'version': prodInfo['productVersion'], 'buildGuid': prodInfo['buildGuid']})
    apPlatform = prodInfo['apPlatform']
    package_name = f'Install_{sapCode}_{version}_{deflang}'
    workspace = os.path.join(dest, package_name)
    products_dir = os.path.join(workspace, 'products')
    os.makedirs(products_dir, exist_ok=True)
    print(f'\n[3/3] Downloading packages to: {workspace}')
    for p in prods_to_download:
        s, v = (p['sapCode'], p['version'])
        product_dir = os.path.join(products_dir, s)
        os.makedirs(product_dir, exist_ok=True)
        app_json = get_application_json(p['buildGuid'])
        packages = app_json['Packages']['Package']
        for pkg in packages:
            is_core = pkg.get('Type') == 'core'
            download_file(cdn + pkg['Path'], product_dir, s, v)
    driver = DRIVER_XML.format(name=product['displayName'], sapCode=prodInfo['sapCode'], version=prodInfo['productVersion'], installPlatform=apPlatform, dependencies='\n'.join([DRIVER_XML_DEPENDENCY.format(sapCode=d['sapCode'], version=d['version']) for d in prodInfo['dependencies']]), language=deflang)
    with open(os.path.join(products_dir, 'driver.xml'), 'w') as f:
        f.write(driver)
    setup_dst = os.path.join(workspace, 'setup.exe')
    if os.path.isfile(HDBOX_SETUP_EXE):
        shutil.copy2(HDBOX_SETUP_EXE, setup_dst)
        setup_copied = True
    else:
        setup_copied = False
    print(f'\n{'======================================================'}')
    print('  DOWNLOAD COMPLETE')
    print(f'{'======================================================'}')
    print(f'  App    : {product['displayName']} {version}')
    print(f'  Folder : {workspace}')
    print(f'{'======================================================'}')
    if setup_copied:
        print('  setup.exe (v6.5.0) staged - installs without license validation.')
        print('\n  To install:')
        print('    1. Open the folder above')
        print('    2. Right-click setup.exe -> Run as administrator')
        print('    3. Once installed, run GenP to patch')
    else:
        print('  WARNING: setup.exe not found at:')
        print(f'    {HDBOX_SETUP_EXE}')
        print('  Locate it manually and place it next to the')
        print('  products/ folder before running.')
    print(f'{'======================================================'}\n')
if __name__ == '__main__':
    _banner: max = ['Adobe Previous Version Downloader', 'Original tool by MP7909', 'Integrated into GenP v4.2.0']
    _con_w = 100
    _pad: print(_pad + '=' * _box_w) = ' ' * max(0, (_con_w - _box_w) // 2)
    for _l in _banner:
        pass
    parser = argparse.ArgumentParser(description='GenP - Adobe Previous Version Downloader')
    parser.add_argument('-l', '--installLanguage', default='en_US', help='en_US / en_GB / ALL')
    parser.add_argument('-s', '--sapCode', help='App SAP code e.g. PHSP, PPRO, AEFT')
    parser.add_argument('-v', '--version', help='Version string e.g. 25.9.1')
    parser.add_argument('-d', '--destination', help='Download destination folder')
    parser.add_argument('-u', '--urlVersion', default=None, help='Manifest version: 4, 5, or 6 (default: 6)')
    parser.add_argument('-A', '--Auth', help='Optional Adobe auth token')
    parser.add_argument('--skipExisting', action='store_true', help='Skip files already downloaded at correct size')
    args = parser.parse_args()
    products, cdn, sapCodes, allowedPlatforms = get_products()
    run_ccdl(products, cdn, sapCodes, allowedPlatforms)