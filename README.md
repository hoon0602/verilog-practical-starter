# Verilog Practical Starter

Verilog를 처음 다루는 사람을 위해 만든 실무 중심 학습 자료다.

포함된 파일:

- `verilog_practical_starter.v`
- `verilog_extra_examples.v`
- `verilog_exercises.md`
- `verilog_practical_starter_guide.md`
- `verilog_1day_curriculum.md`
- `verilog_waveform_walkthrough.md`

## 파일 설명

### `verilog_practical_starter.v`

실무에서 자주 보는 기본 구조를 한 파일에 모아둔 예제다.

- 조합논리 ALU
- 순차논리 카운터
- 비동기 입력 동기화 + 상승엣지 검출
- FSM
- latch가 생기는 나쁜 예 / 고친 예
- testbench

### `verilog_extra_examples.v`

기본 예제를 이해한 뒤 바로 이어서 볼 수 있는 실무형 추가 패턴이다.

- 포화 카운터
- pulse stretch
- 버튼 pulse로 LED 토글

### `verilog_exercises.md`

직접 손으로 풀어보는 연습문제와 짧은 self-check 답안이다.

### `verilog_practical_starter_guide.md`

코드를 어떻게 읽어야 하는지, 각 구조가 왜 필요한지 메커니즘 중심으로 설명한 문서다.

### `verilog_1day_curriculum.md`

하루 안에 핵심을 따라갈 수 있도록 정리한 학습 순서 문서다.

### `verilog_waveform_walkthrough.md`

테스트벤치 기준으로 파형이 어느 시점에 어떻게 보여야 정상인지 설명한 문서다.

## 추천 읽는 순서

1. `verilog_practical_starter_guide.md`
2. `verilog_practical_starter.v`
3. `verilog_extra_examples.v`
4. `verilog_exercises.md`
5. `verilog_1day_curriculum.md`
6. `verilog_waveform_walkthrough.md`

## Git 관리 기준

이 디렉터리만 독립 Git 저장소로 관리한다.

그 이유:

- 홈 디렉터리 전체를 Git으로 묶으면 개인 설정 파일까지 섞인다.
- 학습 자료만 따로 관리해야 변경 이력이 깔끔하다.
- 나중에 GitHub 같은 원격 저장소에 올리기도 쉽다.

## 기본 Git 명령

초기 상태 확인:

```bash
git status
```

변경 파일 확인:

```bash
git diff
```

전체 추가:

```bash
git add .
```

커밋:

```bash
git commit -m "Add verilog practical starter materials"
```

로그 확인:

```bash
git log --oneline --decorate --graph
```

원격 저장소 연결:

```bash
./setup_origin.sh git@github.com:<github-id>/verilog-practical-starter.git
```

작성자 정보 설정:

```bash
git config user.name "Your Name"
git config user.email "your-email@example.com"
```

필수 도구 설치:

```bash
./install_tools.sh
```

GitHub 저장소 생성과 푸시:

```bash
./publish_github.sh
./publish_github.sh --public
./publish_github.sh --name my-verilog-notes
```

## 시뮬레이션 실행 예시

환경에 `iverilog`, `vvp`, `gtkwave` 가 있을 때:

```bash
iverilog -o verilog_practical_starter.out verilog_practical_starter.v
vvp verilog_practical_starter.out
gtkwave verilog_practical_starter.vcd
```

`.vcd`, `.out` 파일은 `.gitignore` 에 넣어두었기 때문에 Git 추적 대상에서 자동 제외된다.

스크립트로 실행:

```bash
./run_sim.sh
./run_sim.sh --wave
```

Makefile이 있는 환경이면:

```bash
make sim
make wave
make clean
```

## 자동화 스크립트

- `install_tools.sh`
  Ubuntu 기준으로 `iverilog`, `gtkwave`, `gh` 를 설치한다.

- `run_sim.sh`
  시뮬레이션 실행 및 선택적으로 GTKWave를 연다.

- `setup_origin.sh`
  이미 존재하는 GitHub 저장소 URL을 `origin` 에 연결한다.

- `publish_github.sh`
  `gh` 가 로그인된 상태라면 GitHub 저장소를 생성하고 현재 브랜치를 푸시한다.
