# Verilog Waveform Walkthrough

이 문서는 [verilog_practical_starter.v](/home/hoon0602/verilog_practical_starter/verilog_practical_starter.v) 의 테스트벤치를 기준으로, 파형에서 어떤 신호가 어떻게 보여야 정상인지 설명한다.

핵심은 단순히 "값이 뭐다"가 아니라, "왜 그 시점에 그 값이 되는지"를 시간축 기준으로 이해하는 것이다.


## 1. 먼저 보는 신호

파형을 열면 처음부터 신호를 많이 올리지 말고 아래만 먼저 보자.

- `clk`
- `rst_n`
- `a`
- `b`
- `op`
- `alu_y`
- `en`
- `count`
- `async_in`
- `pulse`
- `start`
- `work_done`
- `busy`
- `done`

이 순서가 좋은 이유는, 입력과 출력의 원인 관계를 추적하기 쉽기 때문이다.


## 2. 시간축 기준 큰 흐름

테스트벤치의 주요 이벤트는 대략 아래 순서로 일어난다.

1. `0ns ~ 20ns`
reset 구간

2. `20ns ~ 50ns`
ALU 입력 변화 구간

3. `50ns ~ 100ns`
counter 동작 구간

4. `107ns ~ 148ns`
비동기 입력 동기화 및 pulse 생성 구간

5. `148ns ~ 208ns`
FSM 상태 전이 구간

클럭은 `#5` 마다 반전되므로 주기가 10ns다.  
posedge는 `5ns, 15ns, 25ns, 35ns, ...` 에 발생한다.


## 3. reset 구간 해설

초기에는 `rst_n=0` 이다.  
즉 reset이 걸린 상태다.

### 파형에서 보여야 하는 것

- `rst_n` 은 0
- `count` 는 0 유지
- FSM의 `state` 는 내부적으로 `S_IDLE`
- `busy=0`
- `done=0`
- synchronizer 내부 플립플롭들도 0

### 메커니즘 설명

순차논리 블록은 보통 아래 구조를 갖는다.

```text
if (!rst_n)
  레지스터 초기화
else
  정상 동작
```

따라서 reset이 0인 동안은 카운터, FSM 상태, 동기화 플립플롭이 모두 초기화 상태에 머문다.


## 4. ALU 구간 파형 해설

`20ns` 에 아래 값이 들어간다.

- `a=10`
- `b=3`
- `op=000`

ALU는 조합논리이므로 입력이 바뀌면 클럭을 기다리지 않고 바로 출력이 반영된다.

### 예상 파형

1. `20ns` 부근
`alu_y=13`, `alu_carry=0`

2. `30ns` 부근
`op=001` 로 바뀌면 `alu_y=7`

3. `40ns` 부근
`op=100` 로 바뀌면 `alu_y=9`

### 왜 즉시 바뀌는가

ALU는 `always @(*)` 로 작성된 조합논리다.  
즉 내부에 저장소가 없고, 현재 입력 조합에 대해 현재 출력이 곧바로 계산된다.

이걸 알고리즘으로 보면 이렇다.

```text
입력 a, b, op 중 하나라도 바뀌면
즉시 다시 계산해서 y를 결정한다.
```

### 파형에서 확인할 포인트

- `alu_y` 는 클럭 edge와 무관하게 변한다.
- `op` 가 바뀐 직후 `alu_y` 가 따라 바뀌어야 한다.
- 이게 순차논리와 가장 큰 차이다.


## 5. counter 구간 파형 해설

`50ns` 에 `en=1` 이 된다.  
그 뒤 `100ns` 에 `en=0` 으로 돌아간다.

### 중요한 포인트

카운터는 순차논리라서 `en=1` 이 되었다고 바로 `count` 가 바뀌지 않는다.  
반드시 posedge를 기다려야 한다.

### 이 구간의 posedge

- `55ns`
- `65ns`
- `75ns`
- `85ns`
- `95ns`

총 5번이다.

### 예상 파형

- reset 해제 후 시작값: `count=0`
- `55ns` 이후: `count=1`
- `65ns` 이후: `count=2`
- `75ns` 이후: `count=3`
- `85ns` 이후: `count=4`
- `95ns` 이후: `count=5`
- `100ns` 에 `en=0` 이 되므로 이후 증가 멈춤

### 메커니즘 설명

카운터의 알고리즘은 이렇다.

```text
매 posedge에서:
  reset이면 count = 0
  reset이 아니고 en=1이면 count = count + 1
  아니면 count 유지
```

즉 증가 조건이 만족돼도, 레지스터는 posedge에서만 반응한다.

### 파형에서 초보자가 자주 오해하는 부분

- `50ns` 에 `en=1` 이 됐으니 그 즉시 `count` 가 1이 될 거라고 생각함
- 실제로는 `55ns` posedge 후에야 `count` 가 바뀐다


## 6. 비동기 입력 동기화 파형 해설

`async_in` 은 아래처럼 바뀐다.

- `107ns` 에 1
- `118ns` 에 0

이 값은 클럭과 맞지 않는 애매한 시점에 변한다.

### 왜 바로 쓰면 안 되는가

내부 로직은 `clk` 기준으로 동작하는데, `async_in` 은 그 기준을 따르지 않는다.  
그래서 내부 레지스터가 샘플링하는 순간과 입력 변화가 겹치면 메타안정성 위험이 생길 수 있다.

### synchronizer 내부 메커니즘

모듈은 아래처럼 동작한다.

```text
매 posedge에서:
  sync_ff1 <= async_in
  sync_ff2 <= sync_ff1
  sync_ff2_d <= sync_ff2
```

### posedge 기준으로 실제 추적

1. `105ns` posedge
아직 `async_in=0` 이다.

2. `107ns`
`async_in=1` 이 된다.

3. `115ns` posedge
`sync_ff1` 이 1을 받는다.  
하지만 `sync_ff2` 는 아직 0이다.

4. `118ns`
`async_in=0` 으로 내려간다.

5. `125ns` posedge
`sync_ff2` 가 이전 `sync_ff1` 값을 받아 1이 된다.  
동시에 `sync_ff2_d` 는 이전 `sync_ff2` 값인 0을 가진다.

이 순간:

- `sync_ff2=1`
- `sync_ff2_d=0`

이므로

- `pulse=1`

6. `135ns` posedge
이제 `sync_ff2` 는 0이 되고 `sync_ff2_d` 는 1이 되므로 `pulse` 는 다시 0이 된다.

### 예상 파형 핵심

- `async_in` 은 107ns 에 바로 올라감
- 내부 정리된 신호는 바로 따라가지 않음
- `pulse` 는 `125ns ~ 135ns` 부근에서 1클럭 폭으로 보임

### 이 회로의 알고리즘적 의미

```text
외부에서 들어온 애매한 신호를
내부 클럭 도메인으로 안전하게 가져오고,
변화 순간만 1클럭 pulse로 뽑아낸다.
```


## 7. FSM 파형 해설

FSM 입력은 아래처럼 바뀐다.

- `148ns` 에 `start=1`
- `158ns` 에 `start=0`
- `178ns` 에 `work_done=1`
- `188ns` 에 `work_done=0`

### 상태 전이 메커니즘 다시 보기

```text
IDLE:
  start=1 이면 RUN

RUN:
  work_done=1 이면 DONE

DONE:
  다음 클럭에 IDLE 복귀
```

### posedge 기준 추적

이 구간의 관련 posedge는 아래다.

- `145ns`
- `155ns`
- `165ns`
- `175ns`
- `185ns`
- `195ns`

### 실제 해설

1. `145ns` posedge
아직 `start=0` 이므로 상태는 `IDLE`

2. `148ns`
`start=1`

3. `155ns` posedge
`start=1` 이므로 상태가 `RUN` 으로 전이  
이후 `busy=1`

4. `158ns`
`start=0`

5. `165ns`, `175ns` posedge
아직 `work_done=0` 이므로 `RUN` 유지  
따라서 `busy=1`, `done=0`

6. `178ns`
`work_done=1`

7. `185ns` posedge
`work_done=1` 이므로 상태가 `DONE` 으로 전이  
이후 `done=1`, `busy=0`

8. `188ns`
`work_done=0`

9. `195ns` posedge
`DONE` 상태는 1클럭만 유지하고 `IDLE` 로 복귀  
이후 `done=0`, `busy=0`

### 예상 파형 핵심

- `start` 가 올라간 직후 바로 `busy` 가 1이 되는 것이 아니다.
- 다음 posedge인 `155ns` 이후에 `busy=1`
- `work_done` 이 올라간 직후 바로 `done` 이 1이 되는 것이 아니다.
- 다음 posedge인 `185ns` 이후에 `done=1`
- `done` 은 1클럭만 유지되고 `195ns` 이후 다시 0

### 이 회로의 알고리즘적 의미

```text
명령이 들어오면 작업 상태로 들어가고,
작업 완료 신호가 들어오면 완료 pulse를 내보내고,
다시 대기 상태로 복귀한다.
```


## 8. `done` 과 `pulse` 를 왜 놓치기 쉬운가

이 두 신호는 길게 유지되는 레벨 신호가 아니라 짧은 pulse 성격이 강하다.

### 초보자가 흔히 하는 실수

`200ns` 쯤에서 신호를 한 번 보고 `done=0` 이니 동작 안 했다고 판단하는 경우가 많다.

하지만 실제로는:

- `pulse` 는 `125ns ~ 135ns` 근처에서만 1
- `done` 은 `185ns ~ 195ns` 근처에서만 1

즉 그 순간을 놓치면 정상 동작도 못 본다.

그래서 테스트벤치에 아래처럼 이벤트 감시 코드를 넣어둔 것이다.

- `always @(posedge pulse)`
- `always @(posedge clk) if (done)`


## 9. 파형을 읽는 순서

파형이 복잡해 보여도 아래 순서로 보면 된다.

1. `clk`
모든 순차논리의 기준 시간축이다.

2. `rst_n`
reset 중인지 아닌지 먼저 판단한다.

3. 입력 신호
`op`, `en`, `async_in`, `start`, `work_done`

4. 출력 신호
`alu_y`, `count`, `pulse`, `busy`, `done`

5. 필요하면 내부 신호
예: `sync_ff1`, `sync_ff2`, `sync_ff2_d`

이 순서를 지키면 "왜 바뀌었는지"를 따라가기 쉽다.


## 10. 정상 동작 요약표

간단히 정리하면 아래 흐름이 보여야 정상이다.

1. reset 동안 순차논리 출력은 초기값 유지
2. ALU 출력은 입력 변경 직후 즉시 반응
3. counter는 `en=1` 이어도 posedge에서만 증가
4. `async_in` 은 바로 내부 pulse가 되지 않고 두 단계 뒤 정리됨
5. FSM 출력은 입력이 아니라 상태 전이 후에 바뀜
6. `pulse`, `done` 같은 짧은 신호는 특정 구간에서만 잠깐 1이 됨


## 11. 마지막 기준

파형을 볼 때 아래 문장을 스스로 말할 수 있으면 제대로 이해한 것이다.

- "이건 조합논리라서 바로 변한다."
- "이건 순차논리라서 다음 posedge를 기다려야 한다."
- "이 신호는 비동기 입력이라 바로 내부에서 쓰지 않는다."
- "이 출력은 상태가 바뀐 뒤에야 올라간다."
- "짧은 pulse라서 확대해서 봐야 한다."
