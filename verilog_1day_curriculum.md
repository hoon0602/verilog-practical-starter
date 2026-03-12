# Verilog 1-Day Curriculum

이 커리큘럼은 [verilog_practical_starter.v](/home/hoon0602/verilog_practical_starter/verilog_practical_starter.v) 와 [verilog_practical_starter_guide.md](/home/hoon0602/verilog_practical_starter/verilog_practical_starter_guide.md) 를 기준으로 하루 안에 Verilog의 실무 기초를 잡기 위한 학습 순서다.

목표는 세 가지다.

- 조합논리와 순차논리를 구분할 수 있다.
- 코드를 보고 회로 동작을 시간축으로 상상할 수 있다.
- 파형을 보면서 정상 동작과 이상 동작을 구분할 수 있다.


## 1. 하루 목표

하루가 끝났을 때 아래 질문에 답할 수 있으면 된다.

1. `always @(*)` 와 `always @(posedge clk)` 의 차이는 무엇인가
2. 왜 조합논리에서는 기본값이 중요하고, 순차논리에서는 `<=` 가 중요한가
3. 왜 비동기 입력을 바로 쓰면 안 되는가
4. FSM을 왜 상태저장, 다음상태, 출력으로 나누는가
5. 파형에서 `clk`, `rst_n`, `count`, `pulse`, `done` 을 어떻게 읽는가


## 2. 전체 일정

이 일정은 약 6시간에서 7시간 기준이다.

1. 1교시, 60분
Verilog를 코드가 아니라 회로로 보는 관점 익히기

2. 2교시, 60분
조합논리와 latch 이해하기

3. 3교시, 60분
순차논리, 클럭, reset, `<=` 이해하기

4. 4교시, 60분
동기화와 FSM 이해하기

5. 5교시, 60분
테스트벤치와 파형 읽기

6. 6교시, 60분
직접 손으로 예측하고 검증하기


## 3. 1교시: 회로 관점 잡기

읽을 것:

- [verilog_practical_starter_guide.md](/home/hoon0602/verilog_practical_starter/verilog_practical_starter_guide.md) 의 `1. 먼저 알아야 하는 생각법`
- [verilog_practical_starter_guide.md](/home/hoon0602/verilog_practical_starter/verilog_practical_starter_guide.md) 의 `3. reg 와 wire 를 먼저 정리`

집중할 개념:

- Verilog는 소프트웨어처럼 순서대로 실행되는 언어가 아니다.
- 실제로는 회로 연결과 동작 타이밍을 기술하는 언어다.
- `reg`, `wire` 는 타입 이름보다 "어디서 어떻게 할당되느냐"가 중요하다.

이 시간의 핵심 메커니즘:

```text
조합논리:
  입력 변화 -> 즉시 출력 변화

순차논리:
  클럭 엣지 도착 -> 레지스터 값 갱신
```

체크 질문:

1. `reg` 는 왜 항상 플립플롭이 아닌가
2. `wire` 는 주로 어떤 식으로 연결되는가
3. 회로를 읽을 때 가장 먼저 봐야 할 신호는 무엇인가


## 4. 2교시: 조합논리와 latch

읽을 것:

- [verilog_practical_starter.v](/home/hoon0602/verilog_practical_starter/verilog_practical_starter.v#L41) 의 `simple_alu`
- [verilog_practical_starter.v](/home/hoon0602/verilog_practical_starter/verilog_practical_starter.v#L266) 의 `bad_example_latch`
- [verilog_practical_starter.v](/home/hoon0602/verilog_practical_starter/verilog_practical_starter.v#L283) 의 `good_example_no_latch`
- [verilog_practical_starter_guide.md](/home/hoon0602/verilog_practical_starter/verilog_practical_starter_guide.md) 의 `4. 조합논리의 메커니즘`
- [verilog_practical_starter_guide.md](/home/hoon0602/verilog_practical_starter/verilog_practical_starter_guide.md) 의 `8. latch가 생기는 메커니즘`

집중할 개념:

- `always @(*)`
- 기본값 할당
- `case` 와 `default`
- latch가 생기는 이유

손으로 해볼 것:

1. `a=10`, `b=3` 일 때 `op` 를 add, sub, xor 로 바꿔서 `y` 값을 직접 계산한다.
2. `bad_example_latch` 에서 `sel=0` 인 경우 `y` 가 왜 애매해지는지 말로 설명한다.
3. `good_example_no_latch` 가 왜 안전한지 설명한다.

이 시간의 핵심 메커니즘:

```text
조합논리는 저장 기능이 없으므로,
어떤 입력 조합에서도 출력이 즉시 정의되어야 한다.

출력이 정의되지 않는 경로가 있으면,
도구는 이전 값을 유지하는 회로를 만들 수 있고,
그게 latch가 된다.
```

체크 질문:

1. 왜 `always @(*)` 를 쓰는가
2. 왜 블록 시작에서 기본값을 주는가
3. latch는 언제 생기는가


## 5. 3교시: 순차논리와 카운터

읽을 것:

- [verilog_practical_starter.v](/home/hoon0602/verilog_practical_starter/verilog_practical_starter.v#L105) 의 `counter_with_enable`
- [verilog_practical_starter.v](/home/hoon0602/verilog_practical_starter/verilog_practical_starter.v#L315) 의 `blocking_vs_nonblocking`
- [verilog_practical_starter_guide.md](/home/hoon0602/verilog_practical_starter/verilog_practical_starter_guide.md) 의 `5. 순차논리의 메커니즘`
- [verilog_practical_starter_guide.md](/home/hoon0602/verilog_practical_starter/verilog_practical_starter_guide.md) 의 `9. = 와 <= 의 실제 차이`

집중할 개념:

- `posedge clk`
- reset
- enable
- `<=`
- 레지스터가 클럭에서만 변한다는 감각

손으로 해볼 것:

1. `rst_n=0` 일 때 `count` 가 왜 0인지 설명한다.
2. `en=1` 인 동안 posedge가 5번 오면 `count` 가 얼마가 되는지 계산한다.
3. `q1 <= d; q2 <= q1;` 가 왜 2단 지연처럼 보이는지 설명한다.

이 시간의 핵심 메커니즘:

```text
순차논리는 입력이 바뀌어도 바로 출력이 바뀌지 않는다.
클럭 엣지가 와야 레지스터가 새 값을 받아들인다.
```

체크 질문:

1. 왜 순차논리에서는 `<=` 를 기본으로 쓰는가
2. reset은 어떤 타이밍에 상태를 초기화하는가
3. enable은 어떤 경우에 유용한가


## 6. 4교시: 동기화와 FSM

읽을 것:

- [verilog_practical_starter.v](/home/hoon0602/verilog_practical_starter/verilog_practical_starter.v#L140) 의 `sync_and_rise_detect`
- [verilog_practical_starter.v](/home/hoon0602/verilog_practical_starter/verilog_practical_starter.v#L182) 의 `simple_fsm`
- [verilog_practical_starter_guide.md](/home/hoon0602/verilog_practical_starter/verilog_practical_starter_guide.md) 의 `6. 비동기 입력 동기화의 메커니즘`
- [verilog_practical_starter_guide.md](/home/hoon0602/verilog_practical_starter/verilog_practical_starter_guide.md) 의 `7. FSM의 메커니즘`

집중할 개념:

- 2단 동기화
- edge detect
- 상태 전이
- busy, done 같은 제어 신호

손으로 해볼 것:

1. `async_in` 이 클럭 중간에 바뀌었을 때 왜 바로 내부 로직에서 쓰면 위험한지 설명한다.
2. `pulse = sync_ff2 & ~sync_ff2_d` 가 왜 상승엣지만 잡는지 설명한다.
3. FSM에서 `IDLE -> RUN -> DONE -> IDLE` 흐름을 종이에 그린다.

이 시간의 핵심 메커니즘:

```text
비동기 입력:
  외부에서 아무 때나 바뀜

동기화:
  내부 클럭 기준으로 한 번 정리해서 사용

FSM:
  현재 상태 + 입력 -> 다음 상태 결정
  클럭 엣지에서 다음 상태를 현재 상태로 저장
```

체크 질문:

1. 왜 synchronizer가 필요한가
2. 왜 FSM을 여러 블록으로 나누는가
3. `done` 을 1클럭 pulse로 만드는 이유는 무엇인가


## 7. 5교시: 테스트벤치와 파형 읽기

읽을 것:

- [verilog_practical_starter.v](/home/hoon0602/verilog_practical_starter/verilog_practical_starter.v#L360) 의 `tb_verilog_practical_starter`
- [verilog_practical_starter_guide.md](/home/hoon0602/verilog_practical_starter/verilog_practical_starter_guide.md) 의 `10. 테스트벤치의 메커니즘`
- [verilog_practical_starter_guide.md](/home/hoon0602/verilog_practical_starter/verilog_practical_starter_guide.md) 의 `11. 파형 보는 법`
- [verilog_waveform_walkthrough.md](/home/hoon0602/verilog_practical_starter/verilog_waveform_walkthrough.md)

집중할 개념:

- stimulus
- observation
- `$display`
- `$dumpfile`, `$dumpvars`
- `.vcd` 파형

따라할 것:

```bash
iverilog -o verilog_practical_starter.out verilog_practical_starter.v
vvp verilog_practical_starter.out
gtkwave verilog_practical_starter.vcd
```

이 시간의 핵심 메커니즘:

```text
테스트벤치는 입력을 넣고,
시뮬레이터는 시간에 따라 DUT를 동작시키고,
파형은 그 시간축 결과를 보여준다.
```

체크 질문:

1. 왜 `pulse` 같은 신호는 나중에 한 번만 보면 놓칠 수 있는가
2. 왜 파형에서 `clk` 와 `rst_n` 을 먼저 봐야 하는가
3. `count` 는 어떤 타이밍에 바뀌어야 정상인가


## 8. 6교시: 직접 예측하고 검증하기

이 시간에는 코드를 보는 것보다 먼저 결과를 예상해야 한다.

### 연습 1

아래를 손으로 먼저 예측한다.

- `a=10`, `b=3`, `op=000` 이면 `alu_y` 는 얼마인가
- `op=001` 이면 얼마인가
- `op=100` 이면 얼마인가

### 연습 2

`en=1` 인 동안 카운터가 몇 번 증가하는지 posedge 개수를 세서 예측한다.

### 연습 3

`async_in` 이 107ns 에 올라가고 118ns 에 내려갈 때 `pulse` 가 몇 ns 부근에서 1이 되는지 예측한다.

### 연습 4

`start` 와 `work_done` 입력 타이밍을 보고 FSM의 `busy`, `done` 파형을 손으로 먼저 그린다.

### 연습 5

예측한 뒤 [verilog_waveform_walkthrough.md](/home/hoon0602/verilog_practical_starter/verilog_waveform_walkthrough.md) 와 비교한다.


## 9. 하루 마무리 체크

아래가 막히지 않으면 다음 단계로 넘어가도 된다.

1. 조합논리와 순차논리를 코드만 보고 구분할 수 있다.
2. latch가 왜 생기는지 설명할 수 있다.
3. `=` 와 `<=` 를 언제 써야 하는지 설명할 수 있다.
4. synchronizer가 왜 필요한지 설명할 수 있다.
5. FSM의 현재 상태와 다음 상태를 구분할 수 있다.
6. 파형에서 어느 시점에 값이 바뀌어야 하는지 말할 수 있다.


## 10. 다음 날 이어서 할 것

이 문서까지 끝냈다면 다음날은 아래 순서가 좋다.

1. 4비트 업카운터를 직접 작성하기
2. 버튼 입력 1개를 동기화해서 LED 토글 회로 만들기
3. 3상태 FSM을 직접 작성하기
4. 테스트벤치를 직접 만들어서 파형 확인하기


## 11. 한 줄 기준

하루 안에 다 외우는 것이 목적이 아니다.  
코드를 보면 "이건 저장이 있나 없나", "이 값은 언제 바뀌나", "이 신호는 왜 한 클럭 늦게 보이나"를 스스로 설명할 수 있으면 충분하다.
