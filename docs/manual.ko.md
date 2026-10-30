# dockpin 사용 설명서

[English](manual.md) · **한국어**

dockpin은 macOS Dock을 원하는 화면 하나에 고정합니다. 이 설명서는 설치, 메뉴,
어떤 가장자리를 막는지, 그리고 이상할 때 확인할 것을 다룹니다.

- [설치](#설치)
- [처음 실행: 권한 하나](#처음-실행-권한-하나)
- [메뉴](#메뉴)
- [Dock 옮기기](#dock-옮기기)
- [어떤 가장자리를 막나](#어떤-가장자리를-막나)
- [이럴 땐 이렇게 동작합니다](#이럴-땐-이렇게-동작합니다)
- [문제 해결](#문제-해결)
- [개인정보](#개인정보)
- [업데이트와 삭제](#업데이트와-삭제)
- [지원하는 macOS 버전](#지원하는-macos-버전)
- [소스에서 빌드](#소스에서-빌드)

![dockpin 데모](media/demo-ko.gif)

[MP4로 데모 보기](media/demo-ko.mp4)

## 설치

**Homebrew** (권장):

```sh
brew install --cask esteban-eg-kim/tap/dockpin
```

**직접 설치:** [Releases](https://github.com/esteban-eg-kim/dockpin/releases) 에서
`dockpin-x.y.z.zip` 을 받아 압축을 풀고, `dockpin.app` 을 `/Applications` 로 옮긴 뒤
터미널에서 한 번 실행합니다:

```sh
xattr -dr com.apple.quarantine /Applications/dockpin.app
```

dockpin은 자체 인증서로 서명되어 있지만 Apple 공증(notarization)은 받지 않았습니다
(유료 개발자 계정이 필요). 위 명령이 없으면 macOS가 "앱을 열 수 없습니다"라고
합니다. Homebrew로 설치하면 이 단계를 대신 해 줍니다.

## 처음 실행: 권한 하나

dockpin을 열면 메뉴바에 핀 아이콘이 생기고, 환영 창이 권한 하나를 요청합니다.

![환영 창](img/onboarding.png)

1. **Open System Settings** 를 누릅니다.
2. 목록에서 **dockpin** 을 켭니다:
   - macOS 13–26: **개인정보 보호 및 보안 › 손쉬운 사용**
   - macOS 27: **Privacy & Security › Device Control and Data Access**
3. 돌아오면 1초 안에 창이 **Access allowed** 로 바뀝니다. **Done** 을 누릅니다.

필요한 권한은 이것 하나입니다. **입력 모니터링은 필요 없습니다.** 그건 키보드를
읽는 권한인데, dockpin은 키보드를 보지 않습니다.

처음 실행하면 지금 Dock이 있는 화면에 고정됩니다.

## 메뉴

메뉴바의 핀 아이콘을 누릅니다. 메뉴는 영어로 표시됩니다.

![dockpin 메뉴](img/menu.png)

| 항목 | 동작 |
|---|---|
| **Pin the Dock** | dockpin 켜기/끄기. 끄면 메뉴바 아이콘에 사선이 그어지고 Dock은 macOS 기본 동작으로 돌아갑니다. |
| **Keep the Dock on** | 연결된 화면을 이름과 해상도로 보여 줍니다. 체크된 화면이 Dock의 자리입니다. 다른 화면을 고르면 Dock이 바로 그리로 옮겨갑니다. |
| **If It's Unplugged** | 고정 화면이 연결되어 있지 않을 때 Dock을 둘 곳: **Leave the Dock Where It Is**(기본, 지금 자리에 둠) 또는 원하는 화면. 고정 화면이 돌아오면 Dock도 돌아옵니다. |
| **Hold ⌥ to Let It Move** | 켜 두면 `Option` 을 누르고 있는 동안은 Dock이 평소처럼 옮겨갑니다. |
| **Open at Login** | 로그인할 때 dockpin을 자동으로 실행합니다. |
| **⚠️ Allow Accessibility Access…** | 권한이 없을 때만 보입니다. 시스템 설정의 해당 화면을 엽니다. |
| **About dockpin** / **Quit dockpin** | 버전 정보 / 종료 (`⌘Q`). |

메뉴바 아이콘으로 상태를 바로 알 수 있습니다. 꽉 찬 핀은 동작 중, 사선 그어진 핀은
꺼져 있거나 권한을 기다리는 중입니다.

## Dock 옮기기

Dock을 다른 화면으로 옮기는 방법은 두 가지입니다.

**메뉴에서 고르기.** **Keep the Dock on** 에서 화면을 고르면, 0.5초쯤 커서가
사라졌다가 그 화면의 Dock 쪽 가장자리로 밀리고, Dock이 따라온 뒤 커서는 원래 자리로
돌아옵니다. 그 0.5초 동안 마우스를 움직여도 무시되니 기다리면 됩니다.

**⌥ 누른 채 밀기.** **Hold ⌥ to Let It Move** 가 켜져 있으면, `Option` 을 누른 채
다른 화면 아래쪽으로 커서를 밀면 Dock이 평소처럼 옮겨갑니다. 고정 화면 설정은
바뀌지 않는 일회성 이동입니다.

Dock이 다른 곳에 가 있으면 dockpin이 알아서 고정 화면으로 데려옵니다. **Pin the
Dock** 을 다시 켤 때, dockpin이 시작될 때, 고정 화면을 다시 연결했을 때, 그리고
macOS가 직접 Dock을 옮겼을 때입니다. macOS는 모니터가 절전에서 깨어날 때 먼저 켜진
화면으로 Dock을 옮기기도 합니다. 마우스와 상관없는 일이라 막을 수는 없지만, dockpin이
2초마다 확인해서 화면이 안정되면 몇 초 안에 다시 데려옵니다.

`Option` 으로 일부러 옮긴 Dock과, 마우스 버튼을 누르고 있는 동안은 건드리지 않습니다.
화면이 잠겨 있거나, 모니터가 절전 중이거나, 다른 사용자로 전환된 동안에는 커서를 절대
움직이지 않고, 잠금을 풀면 1초 뒤에 확인합니다. 연속 세 번 시도해도 돌아오지 않으면,
커서를 계속 뺏지 않도록 화면 구성이나 설정이 바뀔 때까지 멈춥니다.

Dock을 옮긴 뒤에는 커서를 정확히 원래 자리로 돌려놓고 Dock에도 알려 주기 때문에,
Dock 아이콘이 확대된 채로 남지 않습니다.

## 어떤 가장자리를 막나

Dock은 커서가 화면의 Dock 쪽 가장자리를 미는 것을 보고 옮겨갑니다. dockpin은
마우스 이동을 지켜보다가, 고정 화면이 아닌 모든 화면의 그 가장자리 얇은 띠(4pt)
안에서 생긴 움직임만 버립니다. 커서는 평소처럼 움직이고, Dock만 그 "밀기"를 못
봅니다.

가장자리 중 **바깥쪽** 부분만 막습니다. 가장자리 너머에 다른 화면이 붙어 있는
구간은 평소처럼 넘어갈 수 있습니다:

![막힌 가장자리와 열린 구간](img/edges-ko.png)

이 그림에서는 Dock이 세로 화면에 고정되어 있습니다. 메인 화면 아래쪽은 막히지만,
작은 패널 바로 위 구간은 열려 있어 커서를 아래 패널로 내릴 수 있습니다. 패널 자체의
아래쪽은 막힙니다.

Dock을 왼쪽이나 오른쪽에 두었다면(시스템 설정 › 데스크탑 및 Dock › 화면에서의
위치) 왼쪽/오른쪽 가장자리를 막습니다. 바꾸면 몇 초 안에 알아서 반영됩니다.

## 이럴 땐 이렇게 동작합니다

**고정한 화면을 뽑았을 때.** 그 화면이 없는 동안에는 Dock을 지금 있는 화면에 두거나,
**If It's Unplugged** 에서 고른 화면으로 옮깁니다. 노트북을 외장 모니터에 연결해서도
쓰고 혼자서도 쓴다면, 외장 모니터에 고정하고 대체 화면을 내장 화면으로 정해 두면
됩니다. 고정 화면을 다시 연결하면 Dock이 그 화면으로 돌아갑니다.

**Dock 자동 가리기.** 보이는 Dock과 똑같이 동작합니다. dockpin이 Dock에게 직접
위치를 물어보기 때문에 숨어 있어도 압니다. (나중에 macOS에서 이 방법이 막히면 화면
배치로 추측하는 방식으로 돌아가는데, 그 방식은 숨은 Dock을 못 봅니다. 그때는 메뉴에서
화면을 직접 고를 때만 Dock을 옮깁니다.)

**모니터가 절전에서 깨어날 때.** 화면들이 켜지는 동안 Dock이 잠깐 다른 화면에
나타났다가, 곧 고정 화면으로 알아서 돌아옵니다.

**핫코너.** *다른* 화면의 Dock 쪽 핫코너는 동작하지 않습니다(그 움직임을 버리기
때문). 고정 화면의 핫코너와 다른 모서리의 핫코너는 그대로 동작합니다.

**맨 아래에서의 hover.** 다른 화면의 Dock 쪽 4pt 띠 안에서는 앱이 hover 이벤트를
받지 못합니다. 클릭은 그대로 됩니다.

## 문제 해결

**핀에 사선이 있거나, 메뉴에 "⚠️ Allow Accessibility Access…" 가 보인다.**
권한이 없는 상태입니다. 그 메뉴로 시스템 설정을 열고 dockpin을 켜 주세요. 이미 켜져
있는 것처럼 보이면 다음 항목을 보세요.

**시스템 설정에서는 켜져 있는데 계속 권한을 기다린다.**
그 항목이 예전 버전의 앱 것입니다. 목록에서 **dockpin** 을 선택하고 **−** 로 지운 뒤,
dockpin의 **Open System Settings** (또는 **+**)로 다시 추가하고 켜 주세요.

**Dock이 여전히 다른 화면으로 넘어간다.**
- 핀 아이콘이 꽉 차 있고 **Pin the Dock** 이 체크되어 있는지 확인하세요.
- `Option` 을 누르고 있지 않았는지 확인하세요.
- **Keep the Dock on** 에서 체크된 화면이 원하는 화면인지 확인하세요.

**dockpin이 무엇을 했는지 보기.** dockpin은 화면 변경, Dock 이동과 그 이유, 되돌리기
시도를 로그로 남깁니다. 문제를 재현하면서 터미널에서 아래를 실행하고, 이슈에 출력을
붙여 주세요:

```sh
/usr/bin/log stream --predicate 'subsystem == "io.github.esteban-eg-kim.dockpin"'
```

**화면을 골랐는데 Dock이 안 옮겨졌다.**
- 화면이 잠겨 있었다면 잠금을 풀 때까지 기다립니다.
- 로그에 "giving up" 이 있으면 세 번 시도해도 안 된 것이니 화면을 다시 골라 주세요.
- 고정 화면의 Dock 쪽 가장자리 전체가 다른 화면과 맞닿아 있으면 밀 수 있는 바깥
  구간이 없어서 옮길 수 없습니다. `Option` 으로 옮기거나 시스템 설정 › 디스플레이에서
  배치를 바꿔 주세요.

**"Apple에서 악성 소프트웨어가 있는지 확인할 수 없기 때문에 dockpin을 열 수 없습니다."**
`xattr -dr com.apple.quarantine /Applications/dockpin.app` 을 한 번 실행하거나
Homebrew로 설치하세요.

## 앱 없이 하고 싶다면

macOS에도 Dock을 고정하는 방법이 하나 있습니다. 시스템 설정 › 데스크탑 및 Dock ›
Mission Control 에서 **디스플레이마다 별도의 Spaces 사용**(영문 *Displays have separate Spaces*) 을 끄고 로그아웃했다가 다시
로그인하면, Dock과 메뉴바가 주 디스플레이에만 머뭅니다(주 디스플레이는 시스템 설정 ›
디스플레이에서 메뉴바를 끌어 정합니다).

대신 메뉴바가 주 디스플레이에만 생기고, 창이 두 화면에 걸칠 수 있으며, 전체 화면 앱이
한 화면이 아니라 모든 화면을 차지합니다. dockpin은 별도 Spaces를 그대로 두고, 주
디스플레이가 아닌 화면에도 Dock을 고정할 수 있습니다.

## 개인정보

dockpin에는 네트워크 코드가 없고, 아무것도 수집하지 않으며, 자기 설정(고정 화면과
메뉴 토글)만 `~/Library/Preferences/io.github.esteban-eg-kim.dockpin.plist` 에
저장합니다. 보는 것은 마우스 움직임뿐입니다. 소스는 [GitHub](https://github.com/esteban-eg-kim/dockpin)에 전부 있습니다.

## 업데이트와 삭제

```sh
brew upgrade --cask dockpin              # 업데이트
brew uninstall --cask --zap dockpin      # 앱과 설정 삭제
```

직접 설치했다면: dockpin을 종료하고 `/Applications/dockpin.app` 을 지운 뒤, 손쉬운
사용(또는 Device Control and Data Access) 목록에서 dockpin을 제거하세요.

## 지원하는 macOS 버전

| | |
|---|---|
| 최소 | macOS 13 Ventura |
| 테스트 | macOS 27, Apple 실리콘 |
| 칩 | Apple 실리콘과 Intel (하나의 유니버설 앱) |

메뉴바 메뉴와 로그인 시 실행이 macOS 13에서 추가된 API를 쓰기 때문에 13이
하한입니다. 13–26과 Intel 맥은 동작할 것으로 보지만 아직 직접 테스트하지는
못했습니다. [Issues](https://github.com/esteban-eg-kim/dockpin/issues) 에 결과를
알려 주시면 고맙겠습니다.

## 소스에서 빌드

Xcode Command Line Tools 만 있으면 됩니다 (`xcode-select --install`).

```sh
git clone https://github.com/esteban-eg-kim/dockpin
cd dockpin
scripts/test.sh                 # 가장자리 계산 단위 테스트
ARCHS=arm64 scripts/bundle.sh   # → build/dockpin.app
open build/dockpin.app
```

ad-hoc 빌드는 매번 서명이 바뀌고, macOS는 권한을 서명에 묶기 때문에 다시 빌드할
때마다 권한을 다시 물어봅니다. 피하려면 자체 서명 코드 서명 인증서 하나로
서명하세요: `SIGN_ID="<이름 또는 SHA-1>" scripts/bundle.sh`. 전용 키체인 사용법은
`scripts/bundle.sh` 맨 위 주석을, 그림과 데모 영상을 다시 만드는 법은
`docs/media/make.sh` 를 보세요.
