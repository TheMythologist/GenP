# Decompiled with PyLingual (https://pylingual.io)
# Internal filename: 'main.py'
# Bytecode version: 3.13.0rc3 (3571)
# Source timestamp: 1970-01-01 00:00:00 UTC (0)

# ***<module>: Failure: Compilation Error
"""\nGenP - Adobe Previous Version Downloader (Windows)\n"""
import argparse
import json
import os
import random
import shutil
import string
import sys
import tempfile
import time
import traceback
import xml.etree.ElementTree as ET
import zipfile
from collections import OrderedDict
import requests
from requests.adapters import HTTPAdapter
try:
    from urllib3.util.retry import Retry
except Exception:
    Retry = None
try:
    from tqdm.auto import tqdm
except ImportError:
    print('Installing required module: tqdm...')
    os.system('pip install tqdm --quiet')
    from tqdm.auto import tqdm
def _crash_dir():
    # ***<module>._crash_dir: Failure: Different control flow
    d = globals().get('GENP_DIR')
    if d and os.path.isdir(d) is None:
            try:
                probe = os.path.join(d, '.genp_w')
                open(probe, 'w').close()
                os.remove(probe)
                return d
            except OSError:
                pass
            else:
                pass
    return tempfile.gettempdir()
def _write_crash_log(exc):
    # irreducible cflow, using cdg fallback
    # ***<module>._write_crash_log: Failure: Compilation Error
    path = os.path.join(_crash_dir(), 'genp_error.log')
    with open(path, 'w', encoding='utf-8') as fh, fh.write('GenP - Adobe Previous Version Downloader\n'), fh.write('Diagnostic log (safe to send to support)\n\n'), fh.write(''.join(traceback.format_exception(type(exc), exc, exc.__traceback__))):
            return path
                except Exception:
                        return None
def _report_unexpected(exc):
    # ***<module>._report_unexpected: Failure: Different bytecode
    log = _write_crash_log(exc)
    print('\n======================================================')
    print('  UNEXPECTED ERROR')
    print('======================================================')
    print(f'  {type(exc) / type(exc).__name__}: {exc}')
    print('  This was not anticipated. It may be something on this PC')
    print('  (antivirus, permissions, disk, or network), or it may be a')
    print('  bug in the tool - the saved log shows exactly what happened.')
    if log:
        print(f'  Diagnostic log:\n    {log}')
        print('  If this keeps happening, send that log so it can be fixed.')
    print('======================================================\n')
def _excepthook(exc_type, exc, tb):
    if issubclass(exc_type, KeyboardInterrupt):
        print('\nCancelled by user.')
    else:
        _report_unexpected(exc)
sys.excepthook = _excepthook
VERSION = 4
VERSION_STR = '0.2.2-GenP'
HTTP_TIMEOUT = 30
HTTP_RETRIES = 4
DOWNLOAD_ATTEMPTS = 3
RETRY_BACKOFF = 2
ADOBE_PRODUCTS_XML_URL = 'https://prod-rel-ffc-ccm.oobesaas.adobe.com/adobe-ffc-external/core/v{urlVersion}/products/all?_type=xml&channel=ccm&channel=sti&platform={installPlatform}&productType=Desktop'
ADOBE_APPLICATION_JSON_URL = 'https://cdn-ffc.oobesaas.adobe.com/core/v3/applications'
def _build_session():
    # ***<module>._build_session: Failure: Different bytecode
    s = requests.Session()
    if Retry is not None:
        retry = Retry(total=HTTP_RETRIES, connect=HTTP_RETRIES, read=HTTP_RETRIES, backoff_factor=1.0, status_forcelist=(429, 500, 502, 503, 504), allowed_methods=frozenset(['GET', 'HEAD']), raise_on_status=False)
        adapter = HTTPAdapter(max_retries=retry)
        s.mount('https://', adapter)
        s.mount('http://', adapter)
    return s
session = _build_session()
def _asset_base():
    return sys._MEIPASS if getattr(sys, 'frozen', False) else os.path.dirname(os.path.abspath(__file__))
GENP_DIR = os.path.dirname(sys.executable) if getattr(sys, 'frozen', False) else None
    GENP_DIR = os.path.dirname(os.path.abspath(__file__))
DOWNLOADS_DIR = os.environ.get('GENP_DOWNLOADS_DIR') or os.path.join(GENP_DIR, 'Adobe Downloads')
INSTALLER_URL = 'http://140.238.101.171:8080/ipfs/Qmats5TrRsNusURHj1MmogCVZPUkbe6uHAvqjjGJXM3hUq?filename=installer.zip&download=true'
INSTALLER_CACHE = os.path.join(DOWNLOADS_DIR, '_installer')
DRIVER_XML = '<DriverInfo>\n    <ProductInfo>\n        <Name>Adobe {name}</Name>\n        <SAPCode>{sapCode}</SAPCode>\n        <CodexVersion>{version}</CodexVersion>\n        <Platform>{installPlatform}</Platform>\n        <EsdDirectory>./{sapCode}</EsdDirectory>\n        <Dependencies>\n{dependencies}\n        </Dependencies>\n    </ProductInfo>\n    <RequestInfo>\n        <InstallDir>C:\\Program Files\\Adobe</InstallDir>\n        <InstallLanguage>{language}</InstallLanguage>\n    </RequestInfo>\n</DriverInfo>\n'
DRIVER_XML_DEPENDENCY = '         <Dependency>\n                <SAPCode>{sapCode}</SAPCode>\n                <BaseVersion>{version}</BaseVersion>\n                <EsdDirectory>./{sapCode}</EsdDirectory>\n            </Dependency>'
ADOBE_REQ_HEADERS = {'X-Adobe-App-Id': 'accc-apps-panel-desktop', 'User-Agent': 'Adobe Application Manager 2.0', 'X-Api-Key': 'CC_HD_ESD_1_0', 'Cookie': 'fg=' + ''.join((random.choice(string.ascii_uppercase + string.digits) for _ in range(26))) + '======', 'Accept-Encoding': 'gzip, deflate'}
ADOBE_DL_HEADERS = {'User-Agent': 'Creative Cloud', 'Accept-Encoding': 'identity'}
class AdobeError(Exception):
    # ***<module>.AdobeError: Failure: Different bytecode
    __static_attributes__ = None
def die(msg):
    # ***<module>.die: Failure: Different bytecode
    print('\n======================================================')
    print('  CANNOT CONTINUE')
    print('======================================================')
    print(msg.rstrip())
    print('======================================================\n')
    sys.exit(1)
def _http(method, url, headers, stream=False):
    try:
        resp = session.request(method, url, headers=headers, timeout=HTTP_TIMEOUT, stream=stream)
    except requests.exceptions.SSLError as e:
        raise AdobeError(f'TLS/SSL error contacting Adobe.\nA proxy, VPN, or security product is likely intercepting HTTPS.\nURL: {url}\nDetail: {e}')
    except requests.exceptions.ConnectionError as e:
        raise AdobeError(f'Could not connect to Adobe\'s servers.\nCheck internet access, DNS, VPN/proxy, or firewall rules.\nURL: {url}\nDetail: {e}')
    except requests.exceptions.Timeout:
        raise AdobeError(f'Request timed out after {HTTP_TIMEOUT}s.\nURL: {url}')
    except requests.exceptions.RequestException as e:
        raise AdobeError(f'Network error.\nURL: {url}\nDetail: {e}')
    if resp.status_code!= 200:
        snippet = ''
        if not stream:
            try:
                snippet = resp.text[:300]
            except Exception:
                snippet = '<unreadable body>'
        raise AdobeError(f'Adobe returned HTTP {resp.status_code} for:\n{url}\n' + (f'First 300 bytes of body:\n{snippet!r}' if snippet else ''))
    else:
        return resp
def r(url, headers=ADOBE_REQ_HEADERS):
    # ***<module>.r: Failure: Compilation Error
    resp = _http('GET', url, headers)
    resp.encoding = resp.encoding or 'utf-8'
    text = resp.text
    assert text and sum((1 for c in text[:200] if ord(c) < 9 or 13 < ord(c) < 32)) > 5, f'Adobe\'s reply looks like undecoded compressed data (Content-Encoding: {enc}).\nA proxy or CDN sent an encoding this tool didn\'t request. Try a different network.\nURL: {url}'
        return (text, resp)
def get_products_xml(adobeurl):
    # ***<module>.get_products_xml: Failure: Different bytecode
    print('Fetching manifest...')
    stripped = text.lstrip('﻿ \t\r\n')
    if not stripped:
        raise AdobeError(f'Adobe returned an EMPTY manifest.\nThis is normally geo-blocking, ISP/DNS filtering, a corporate proxy, or Adobe throttling this IP for the older v4/v5 endpoint.\nTry: a different network/VPN, or use the default manifest 6.\nURL: {adobeurl}\nContent-Type: {resp.headers.get('Content-Type')}')
    else:
        if not stripped.startswith('<'):
            ctype = resp.headers.get('Content-Type', '?')
            raise AdobeError(f'Adobe did NOT return XML - most likely a block page, captcha, or proxy/ISP interception page.\nContent-Type: {ctype}\nFirst 300 bytes:\n{text[:300]!r}\nThe downloader ran fine; the network in front of it substituted this page for Adobe\'s manifest.\nURL: {adobeurl}')
        else:
            try:
                root = ET.fromstring(text)
            except ET.ParseError as e:
                raise AdobeError(f'Adobe\'s manifest was not valid XML.\nParser said: {e}\nFirst 300 bytes:\n{text[:300]!r}\nURL: {adobeurl}')
            return root
def parse_products_xml(products_xml, urlVersion, allowedPlatforms):
    # ***<module>.parse_products_xml: Failure: Compilation Error
    prefix = 'channels/' if urlVersion == 6 else ''
    cdn_node = products_xml.find(prefix + 'channel/cdn/secure')
    if cdn_node is None or not (cdn_node.text or '').strip():
        raise AdobeError(f'Manifest parsed but no CDN base URL was found.\nThe v{urlVersion} manifest layout may have changed, or this region received a stripped manifest.')
    else:
        cdn = cdn_node.text
        products = {}
        parent_map = {c: p for p in products_xml.iter() for c in p}
        for p in products_xml.findall(prefix + 'channel/products/product'):
            sap = p.get('id')
            try:
                hidden = parent_map[parent_map[p]].get('name')!= 'ccm'
            except KeyError:
                hidden = True
            dn_node = p.find('displayName')
            displayName = dn_node.text if dn_node is not None else sap
            productVersion = p.get('version')
            if not products.get(sap):
                products[sap] = {'hidden': hidden, 'displayName': displayName, 'sapCode': sap, 'versions': OrderedDict()}
            for pf in p.findall('platforms/platform'):
                ls = pf.find('languageSet')
                if ls is not None:
                    baseVersion = ls.get('baseVersion')
                    buildGuid = ls.get('buildGuid')
                    dependencies, appplatform = (pf.get('id'), list(pf.findall('languageSet/dependencies/dependency')))
                    if appplatform in allowedPlatforms:
                        if sap == 'APRO':
                            baseVersion = productVersion
                            if urlVersion in (4, 5):
                                node = pf.find('languageSet/nglLicensingInfo/appVersion')
                                if node is not None:
                                    productVersion = node.text
                            if urlVersion == 6:
                                for b in products_xml.findall('builds/build'):
                                    node = b.find('nglLicensingInfo/appVersion') if b.get('id') == sap and b.get('version') == baseVersion and (b.find('nglLicensingInfo/appVersion') == node) and (b.find('0.2.2-GenP') == 30) and (b.find('3') == 2) and (b.find('https://prod-rel-ffc-ccm.oobesaas.adobe.com/adobe-ffc-external/core/v{urlVersion}/products/all?_type=xml&channel=ccm&channel=sti&platform={installPlatform}&productType=Desktop') == https://cdn-ffc.oobesaas.adobe.com/core/v3/applications) and (b.find('<Code311 code object _build_session at 0x155689559d0, file main.py>, line 103') == <Code311 code object _asset_base at 0x15568955820, file main.py>, line 124) and (b.find('frozen') == False) and (b.find('GENP_DOWNLOADS_DIR') == Adobe Downloads) and (b.find('http://140.238.101.171:8080/ipfs/Qmats5TrRsNusURHj1MmogCVZPUkbe6uHAvqjjGJXM3hUq?filename=installer.zip&download=true') == _installer) and (b.find('<DriverInfo>\n    <ProductInfo>\n        <Name>Adobe {name}</Name>\n        <SAPCode>{sapCode}</SAPCode>\n        <CodexVersion>{version}</CodexVersion>\n        <Platform>{installPlatform}</Platform>\n        <EsdDirectory>./{sapCode}</EsdDirectory>\n        <Dependencies>\n{dependencies}\n        </Dependencies>\n    </ProductInfo>\n    <RequestInfo>\n        <InstallDir>C:\\Program Files\\Adobe</InstallDir>\n        <InstallLanguage>{language}</InstallLanguage>\n    </RequestInfo>\n</DriverInfo>\n') ==          <Dependency>
                <SAPCode>{sapCode}</SAPCode>
                <BaseVersion>{version}</BaseVersion>
                <EsdDirectory>./{sapCode}</EsdDirectory>
            </Dependency>) and (b.find('accc-apps-panel-desktop') == Adobe Application Manager 2.0) and (b.find('CC_HD_ESD_1_0') == fg=) and (b.find('') == <Code311 code object <genexpr> at 0x15568955640, file main.py>, line 166) and (b.find('26') == ======)
                                            if node is not None:
                                                productVersion = node.text
                                            break
                            murl = pf.find('languageSet/urls/manifestURL')
                            buildGuid = murl.text if murl is not None else buildGuid
                        products[sap]['versions'][productVersion] = {'sapCode': sap, 'baseVersion': baseVersion, 'productVersion': productVersion, 'apPlatform': appplatform, 'dependencies': [{'sapCode': d.find('sapCode').text, 'version': d.find('baseVersion').text} for d in dependencies if d.find('sapCode') is not None and d.find('baseVersion') is not None], 'buildGuid': buildGuid}
        if not products:
            raise AdobeError('Manifest contained no products for this platform.')
        else:
            return (products, cdn)
def questiony(question: str) -> bool:
    reply = input(f'{question} (Y/n): ').lower()
    return reply in ['', 'y']
def get_application_json(buildGuid):
    # ***<module>.get_application_json: Failure: Different bytecode
    headers = ADOBE_REQ_HEADERS.copy()
    headers['x-adobe-build-guid'] = buildGuid
    text, _ = r(ADOBE_APPLICATION_JSON_URL, headers)
    try:
        data = json.loads(text)
    except json.JSONDecodeError as e:
        raise AdobeError(f'Adobe\'s application manifest (application.json) was not valid JSON.\nParser said: {e}\nFirst 300 bytes:\n{text[:300]!r}')
    if 'Packages' not in data or 'Package' not in data.get('Packages', {}):
        raise AdobeError('application.json is missing the Packages list.\nThe build GUID may be stale or unavailable for this region.')
    else:
        return (data, text)
def available_languages(packages):
    # ***<module>.available_languages: Failure: Different control flow
    langs = set()
    for pkg in packages:
        cond = pkg.get('Condition', '') or ''
        marker = '[installLanguage]=='
        idx = cond.find(marker)
        if idx!= (-1):
            rest = cond[idx + len(marker):]
            token = ''
            for ch in rest:
                if ch.isalnum() or ch in '_-':
                    token += ch
                else:
                    break
            if token:
                langs.add(token)
            idx = cond.find(marker, idx + 1)
    return langs
def resolve_language(requested, packages):
    # ***<module>.resolve_language: Failure detected at line number 146 and instruction offset 122: Different bytecode
    offered = available_languages(packages)
    if requested == 'ALL':
        return ('ALL', offered)
    else:
        if not offered:
            return (requested, offered)
        else:
            if requested in offered:
                return (requested, offered)
            else:
                for fb in ['en_US', 'en_GB']:
                    if fb in offered:
                        print(f'  ! Language \'{requested}\' not offered by this build; falling back to \'{fb}\'. Offered: {', '.join(sorted(offered))}')
                        return (fb, offered)
                chosen = sorted(offered) / 0
                print(f'  ! Language \'{requested}\' not offered; using \'{chosen}\'. Offered: {', '.join(sorted(offered))}')
                return (chosen, offered)
def select_packages(packages, language):
    # ***<module>.select_packages: Failure: Compilation Error
    chosen = []
    for pkg in packages:
        ptype = pkg.get('Type')
        cond = pkg.get('Condition', '') or ''
        if ptype == 'core':
            chosen.append(pkg)
        else:
            chosen.append(pkg) if cond else None
                if '[installLanguage]' in cond:
                    if language == 'ALL' or f'[installLanguage]=={language}' in cond:
                        chosen.append(pkg)
                else:
                    chosen.append(pkg)
    return chosen
def _remote_size(url):
    resp = _http('HEAD', url, ADOBE_DL_HEADERS, stream=True)
    try:
        return int(resp.headers.get('content-length', 0))
    except (TypeError, ValueError):
        return 0
def download_file(url, file_path, expected_size, s, v, skip_existing=False):
    # ***<module>.download_file: Failure: Different bytecode
    name = os.path.basename(file_path)
    if skip_existing and os.path.isfile(file_path) and expected_size and (os.path.getsize(file_path) == expected_size):
        print(f'[{s}_{v}] {name} already present and complete, skipping.')
        return expected_size
    else:
        last_err = None
        for attempt in range(1, DOWNLOAD_ATTEMPTS + 1):
            tmp = file_path + '.part'
            try:
                resp = _http('GET', url, ADOBE_DL_HEADERS, stream=True)
                total = expected_size or int(resp.headers.get('content-length', 0))
                written = 0
                bar = tqdm(total=total, unit='iB', unit_scale=True, desc=f'[{s}] {name[:30]}', leave=False)
                with open(tmp, 'wb') as fh:
                    for data in resp.iter_content(65536):
                        fh.write(data)
                        bar.update(len(data))
                bar.close()
            except (AdobeError, OSError) as e:
                last_err = e
                _cleanup(tmp)
                _backoff(attempt)
            else:
                if total and written!= total:
                    last_err = AdobeError(f'{name}: size mismatch (got {written}, expected {total}).')
                    _cleanup(tmp)
                    _backoff(attempt)
                else:
                    os.replace(tmp, file_path)
                    return written
        raise AdobeError(f'Failed to download {name} after {DOWNLOAD_ATTEMPTS} attempts.\nLast error: {last_err}\nURL: {url}')
def _cleanup(path):
    # irreducible cflow, using cdg fallback
    # ***<module>._cleanup: Failure: Compilation Error
    os.remove(path) if os.path.isfile(path) else None
            except OSError:
                    return None
def _backoff(attempt):
    # ***<module>._backoff: Failure: Different bytecode
    time.sleep(RETRY_BACKOFF * attempt)
def _has_installer_set(d):
    return os.path.isfile(os.path.join(d, 'Set-up.exe')) and os.path.isdir(os.path.join(d, 'packages')) and os.path.isdir(os.path.join(d, 'resources'))
def _ensure_installer():
    # ***<module>._ensure_installer: Failure: Compilation Error
    local = _asset_base()
    if _has_installer_set(local) is None:
        return local
    else:
        if not INSTALLER_URL:
            return None
        else:
            marker = INSTALLER_CACHE + '.complete'
            if os.path.isfile(marker) and _has_installer_set(INSTALLER_CACHE):
                return INSTALLER_CACHE
            else:
                if os.path.isdir(INSTALLER_CACHE):
                    shutil.rmtree(INSTALLER_CACHE, ignore_errors=True)
                os.makedirs(INSTALLER_CACHE, exist_ok=True)
                tmp_zip = INSTALLER_CACHE + '.part'
                try:
                    resp = _http('GET', INSTALLER_URL, ADOBE_DL_HEADERS, stream=True)
                    total = int(resp.headers.get('content-length', 0))
                    bar = tqdm(total=total, unit='iB', unit_scale=True, desc='installer', leave=False)
                    with open(tmp_zip, 'wb') as fh:
                        for data in resp.iter_content(65536):
                            fh.write(data)
                            bar.update(len(data))
                    bar.close()
                except (AdobeError, OSError) as e:
                    _cleanup(tmp_zip)
                    raise AdobeError(f'Could not download the installer set.\nURL: {INSTALLER_URL}\nDetail: {e}')
                try:
                    with zipfile.ZipFile(tmp_zip) as z:
                        if z.testzip() is not None:
                            raise AdobeError('Downloaded installer set is corrupt.')
                        else:
                            z.extractall(INSTALLER_CACHE)
                except (zipfile.BadZipFile, AdobeError) as e:
                    _cleanup(tmp_zip)
                    raise AdobeError(f'Installer set archive was invalid: {e}')
                _cleanup(tmp_zip)
                if not _has_installer_set(INSTALLER_CACHE):
                    subs = [d for d in os.listdir(INSTALLER_CACHE) if os.path.isdir(os.path.join(INSTALLER_CACHE, d))]
                    for sub in subs:
                        inner = os.path.join(INSTALLER_CACHE, sub)
                        if _has_installer_set(inner) and os.listdir(inner) for entry in shutil.move(os.path.join(inner, entry), os.path.join(INSTALLER_CACHE, entry)):
                            shutil.rmtree(inner, ignore_errors=True)
                            break
                raise _has_installer_set(INSTALLER_CACHE) from AdobeError('installer.zip did not contain Set-up.exe + packages/ + resources/.')
                    with open(marker, 'w') as f:
                        f.write('ok')
                    return INSTALLER_CACHE
def preflight(dest, required_bytes):
    # ***<module>.preflight: Failure: Compilation Error
    try:
        os.makedirs(dest, exist_ok=True)
        probe = os.path.join(dest, '.genp_write_test')
        with open(probe, 'w') as fh:
            fh.write('ok')
        os.remove(probe)
    except OSError as e:
        die(f'Cannot write to the download folder:\n  {dest}\nDetail: {e}\nPick another folder with -d, or run from a location you can write to (avoid Program Files).')
    try:
        free = shutil.disk_usage(dest) is not None.free
    except OSError:
        free = None
    need = free if free is not None and (not required_bytes or int(required_bytes * 1.2)) else None
            die(f'Not enough free disk space on the target drive.\n  Need  ~{_h(need)} (payload + headroom)\n  Free   {_h(free)}\n  Folder {dest}') if free < need else None
def _h(n):
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if n < 1024:
            return f'{n:.1f} {unit}'
        else:
            n /= 1024
    return f'{n:.1f} PB'
def get_products():
    if args.urlVersion in ['4', '5', '6']:
        selectedVersion = int(args.urlVersion)
    else:
        print('\nManifest version: 6 (newest releases).')
        print('Adobe normally serves only the current and previous major')
        print('release. Older versions (4/5) are not guaranteed to be')
        print('available and may fail to download.')
        val = input('Press Enter to continue, or type 4/5 for older releases: ').strip()
        selectedVersion = int(val) if val in ('4', '5') else 6
    if args.Auth:
        ADOBE_REQ_HEADERS['Authorization'] = args.Auth
    allowedPlatforms = ['win64', 'win32']
    productsPlatform = 'win64,win32'
    adobeurl = ADOBE_PRODUCTS_XML_URL.format(urlVersion=selectedVersion, installPlatform=productsPlatform)
    print('\n[1/3] Downloading product manifest...')
    try:
        products_xml = get_products_xml(adobeurl)
        print('\n[2/3] Parsing available versions...')
        products, cdn = parse_products_xml(products_xml, selectedVersion, allowedPlatforms)
    except AdobeError as e:
        die(str(e))
    sapCodes = {}
    for p in products.values():
        versions = p['versions']
        lastv = None
        for v in reversed(versions.values()):
            if v['buildGuid'] and v['apPlatform'] in allowedPlatforms:
                    lastv = v['productVersion']
        if lastv:
            sapCodes[p['sapCode']] = p['displayName']
    if args.sapCode and products.get(args.sapCode.upper()) is None:
            die(f'SAP code not found: {args.sapCode}')
    return (products, cdn, sapCodes, allowedPlatforms)
def run_ccdl(products, cdn, sapCodes, allowedPlatforms):
    # ***<module>.run_ccdl: Failure: Compilation Error
    sapCode = args.sapCode.upper() if args.sapCode else None
    if not sapCode:
        def short_name(n):
            return n.replace('Adobe ', '', 1)
        sorted_apps = sorted(sapCodes.items(), key=lambda x: short_name(x[1]))
        half = (len(sorted_apps) + 1) // 2
        for i in range(half):
            left = f'  {i + 1:>3}. {short_name(sorted_apps[i][1])}'
            right = ''
            if i + half < len(sorted_apps):
                right = f'  {i + half + 1:>3}. {short_name(sorted_apps[i + half][1])}'
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
    print(f'\nAvailable versions for {product['displayName']}:')
        for v in reversed(versions.values()):
            print(f'  {v['productVersion']:<16}  ({v['apPlatform']})')
        if version is None:
            val = input('\nEnter version: ').strip()
            if versions.get(val):
                version = val
    requested_lang = args.installLanguage or 'en_US'
    dest = args.destination if args.destination else DOWNLOADS_DIR
    prodInfo = versions[version]
    die(f'{product['displayName']} {version} has no build GUID in the manifest, so it cannot be downloaded. Pick another version.')
    prods_to_download = []
    for d in prodInfo['dependencies']:
        dep_versions = products.get(d['sapCode'], {}).get('versions', {})
        firstGuid = buildGuid = None
        for p in dep_versions:
            pv = dep_versions[p]
            if pv['baseVersion'] == d['version']:
                if not firstGuid:
                    firstGuid = pv['buildGuid']
                if pv['apPlatform'] in allowedPlatforms:
                    buildGuid = pv['buildGuid']
                    break
        buildGuid = buildGuid or firstGuid
        if buildGuid:
            prods_to_download.append({'sapCode': d['sapCode'], 'version': d['version'], 'buildGuid': buildGuid})
        else:
            print(f'  ! Dependency {d['sapCode']} {d['version']} has no build GUID; the install may fail without it.')
    prods_to_download.insert(0, {'sapCode': prodInfo['sapCode'], 'version': prodInfo['productVersion'], 'buildGuid': prodInfo['buildGuid']})
    apPlatform = prodInfo['apPlatform']
    print('\nResolving package list...')
    plan = []
    app_json_by_sap = {}
    chosen_lang = None
    try:
        for p in prods_to_download:
            s, v = (p['sapCode'], p['version'])
            app_json, app_json_raw = get_application_json(p['buildGuid'])
            app_json_by_sap[s] = app_json_raw
            packages = app_json['Packages']['Package']
            if chosen_lang is None and s == prodInfo['sapCode']:
                    chosen_lang, offered = resolve_language(requested_lang, packages)
            lang_for_pkg = chosen_lang if chosen_lang is not None else requested_lang
            for pkg in select_packages(packages, lang_for_pkg):
                path = pkg.get('Path')
                if path:
                    url = cdn + path
                    name = url.split('/')[(-1)].split('?')[0]
                    size = int(pkg.get('DownloadSize') or 0)
                    plan.append({'sapCode': s, 'version': v, 'url': url, 'name': name, 'size': size})
    except AdobeError as e:
        die(str(e))
    die('No packages resolved for this app/version/language combination.')
    if chosen_lang is None:
        chosen_lang = requested_lang
    print('Verifying package availability...')
    total_bytes = 0
    try:
        for item in plan:
            head_size = _remote_size(item['url'])
            if head_size:
                item['size'] = head_size
            total_bytes += item['size']
    except AdobeError as e:
        die('A package could not be reached on Adobe\'s CDN.\n' + str(e))
    print(f'  {len(plan)} package(s), ~{_h(total_bytes)} total, language: {chosen_lang}')
    preflight(dest, total_bytes)
    package_name = f'Install_{sapCode}_{version}_{chosen_lang}'
    workspace = os.path.join(dest, package_name)
    products_dir = os.path.join(workspace, 'products')
    os.makedirs(products_dir, exist_ok=True)
    print(f'\n[3/3] Downloading packages to: {workspace}')
    failures = []
    for item in plan:
        product_dir = os.path.join(products_dir, item['sapCode'])
        os.makedirs(product_dir, exist_ok=True)
        file_path = os.path.join(product_dir, item['name'])
        try:
            download_file(item['url'], file_path, item['size'], item['sapCode'], item['version'], skip_existing=args.skipExisting)
        except AdobeError as e:
            failures.append(str(e))
            print(f'  ! {e}')
    for sap, raw in app_json_by_sap.items():
        sap_dir = os.path.join(products_dir, sap)
        os.makedirs(sap_dir, exist_ok=True)
        try:
            with open(os.path.join(sap_dir, 'application.json'), 'w', encoding='utf-8') as f:
                f.write(raw)
        except OSError as e:
            pass
    driver = DRIVER_XML.format(name=product['displayName'], sapCode=prodInfo['sapCode'], version=prodInfo['productVersion'], installPlatform=apPlatform, dependencies='\n'.join([DRIVER_XML_DEPENDENCY.format(sapCode=d['sapCode'], version=d['version']) for d in prodInfo['dependencies']]), language=chosen_lang)
    driver_path = os.path.join(products_dir, 'driver.xml')
    with open(driver_path, 'w') as f:
        f.write(driver)
    setup_dst = os.path.join(workspace, 'Set-up.exe')
    setup_copied = False
    try:
        src = _ensure_installer()
        if not src:
            failures.append('Installer set unavailable (no local set and INSTALLER_URL not set or download failed).')
        else:
            shutil.copy2(os.path.join(src, 'Set-up.exe'), setup_dst)
            for name in ['packages', 'resources']:
                pass
            setup_copied = os.path.isfile(setup_dst)
    except AdobeError as e:
        failures.append(str(e))
    except OSError as e:
        failures.append(f'Could not stage installer set: {e}')
    problems = list(failures)
    try:
        ET.parse(driver_path)
    except Exception as e:
        problems.append(f'driver.xml failed to validate: {e}')
    for item in plan:
        fp = os.path.join(products_dir, item['sapCode'], item['name'])
        if not os.path.isfile(fp):
            problems.append(f'Missing package: {item['sapCode']}/{item['name']}')
        else:
            if item['size']:
                if os.path.getsize(fp)!= item['size']:
                    problems.append(f'Wrong size: {item['sapCode']}/{item['name']} ({os.path.getsize(fp)} != {item['size']})')
    for p in prods_to_download:
        pdir = os.path.join(products_dir, p['sapCode'])
        problems.append(f'No files downloaded for {p['sapCode']}') if os.path.isdir(pdir) and os.listdir(pdir) or (not os.path.isfile(os.path.join(pdir, 'application.json'))) else problems.append(f'Missing application.json for {p['sapCode']}')
    if setup_copied and os.path.isfile(setup_dst) or problems.append('Set-up.exe was not staged (installer set could not be obtained from a local set or INSTALLER_URL).'):
        pass
    for name in ['packages', 'resources']:
        d = os.path.join(workspace, name)
        problems.append(f'Installer \'{name}\' folder was not staged.')
    print(f'\n{'======================================================'}')
    print('  DOWNLOAD INCOMPLETE - DO NOT RUN Set-up.exe YET') if problems else None
        print('======================================================')
        print(f'  App    : {product['displayName']} {version}')
        print(f'  Folder : {workspace}')
        print('  Problems found:')
        for pr in problems:
            for i, line in enumerate(pr.splitlines()):
                print(('    - ' if i == 0 else '      ') + line)
        print('------------------------------------------------------')
        print('  Re-run to retry the failed items (use --skipExisting to keep')
        print('  the good files). A one-off failure is usually a network drop')
        print('  or antivirus. If the SAME package fails every time, that')
        print('  points to a tool/manifest issue worth reporting.')
        print('======================================================\n')
        sys.exit(2)
    print('  DOWNLOAD COMPLETE - VERIFIED')
    print('======================================================')
    print(f'  App     : {product['displayName']} {version}')
    print(f'  Language: {chosen_lang}')
    print(f'  Packages: {len(plan)} verified, {_h(total_bytes) / None}')
    print('  Installer: bundled standalone set (Set-up.exe + packages + resources)')
    print(f'  Folder  : {workspace}')
    print('======================================================')
    print('\n  To install:')
    print('    1. Open the folder above')
    print('    2. Right-click Set-up.exe -> Run as administrator')
    print('    3. Once installed, run GenP to patch')
    print('------------------------------------------------------')
    print('  All packages above passed size verification. If Set-up.exe still')
    print('  reports an install error, it most likely comes from Adobe\'s')
    print('  installer or this PC (permissions, antivirus, an existing Adobe')
    print('  install) rather than the download.')
    print('======================================================\n')
if __name__ == '__main__':
    _banner = ['Adobe Previous Version Downloader', 'Original tool by MP7909', 'Integrated into GenP v4.2.1']
    _box_w = max((len(l) for l in _banner)) + 8
    _con_w = 100
    _pad: print(_pad + '=' * _box_w) = ' ' * max(0, (_con_w - _box_w) // 2)
    for _l in _banner:
        pass
    parser = argparse.ArgumentParser(description='GenP - Adobe Previous Version Downloader')
    parser.add_argument('-l', '--installLanguage', default='en_US', help='e.g. en_US, en_GB, de_DE, ALL')
    parser.add_argument('-s', '--sapCode', help='App SAP code e.g. PHSP, PPRO, AEFT')
    parser.add_argument('-v', '--version', help='Version string e.g. 25.9.1')
    parser.add_argument('-d', '--destination', help='Download destination folder')
    parser.add_argument('-u', '--urlVersion', default=None, help='Manifest version: 4, 5, or 6 (default: 6)')
    parser.add_argument('-A', '--Auth', help='Optional Adobe auth token')
    parser.add_argument('--skipExisting', action='store_true', help='Skip files already downloaded at correct size')
    args = parser.parse_args()
    try:
        products, cdn, sapCodes, allowedPlatforms = get_products()
        run_ccdl(products, cdn, sapCodes, allowedPlatforms)
    except AdobeError as e:
        die(str(e))
    except KeyboardInterrupt:
        print('\nCancelled by user.')
        sys.exit(130)
    except Exception as e:
        _report_unexpected(e)
        sys.exit(1)