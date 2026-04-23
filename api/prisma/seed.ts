import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

async function main() {
  // ─── Daily Quotes (31개) ───────────────────────────────────────────
  await prisma.dailyQuote.deleteMany();
  await prisma.dailyQuote.createMany({
    data: [
      { text: '부는 쓰는 것을 아끼는 데서 시작된다.', author: '키케로' },
      { text: '돈을 모으는 것은 나무를 심는 것과 같다. 시간이 최고의 비료다.', author: '워런 버핏' },
      { text: '작은 지출을 조심하라. 작은 구멍이 큰 배를 침몰시킨다.', author: '벤자민 프랭클린' },
      { text: '부자가 되는 비결은 내일 할 일을 오늘 하고, 오늘 먹을 것을 내일 먹는 것이다.', author: '마크 트웨인' },
      { text: '투자의 첫 번째 규칙은 돈을 잃지 않는 것이고, 두 번째 규칙은 첫 번째 규칙을 잊지 않는 것이다.', author: '워런 버핏' },
      { text: '저축은 미래의 나에게 보내는 선물이다.', author: '작자 미상' },
      { text: '복리는 세계 8번째 불가사의다. 이해하는 자는 벌고, 모르는 자는 지불한다.', author: '알베르트 아인슈타인' },
      { text: '재정적 자유는 사치가 아니라 선택의 자유다.', author: '로버트 기요사키' },
      { text: '수입의 일부를 먼저 저축하라. 스스로에게 먼저 지불하라.', author: '조지 클레이슨' },
      { text: '돈은 좋은 하인이지만 나쁜 주인이다.', author: '프랜시스 베이컨' },
      { text: '기회는 준비된 자에게 온다. 오늘의 기록이 내일의 부를 만든다.', author: '루이 파스퇴르' },
      { text: '시작이 반이다. 오늘 한 걸음이 내일의 자산이 된다.', author: '아리스토텔레스' },
      { text: '부를 쌓는 것은 마라톤이지 단거리 경주가 아니다.', author: '데이브 램지' },
      { text: '당신이 잠자는 동안에도 돈이 일하게 하라.', author: '워런 버핏' },
      { text: '목표 없는 항해에 순풍은 없다.', author: '세네카' },
      { text: '지출을 줄이는 것은 수입을 늘리는 것만큼 가치 있다.', author: '토머스 풀러' },
      { text: '오늘의 결정이 10년 후의 나를 만든다.', author: '작자 미상' },
      { text: '꾸준함은 재능을 이긴다. 매일 조금씩이 기적을 만든다.', author: '작자 미상' },
      { text: '가장 좋은 투자는 자기 자신에 대한 투자다.', author: '워런 버핏' },
      { text: '부자는 돈을 관리하고, 가난한 자는 돈에 관리당한다.', author: 'T. 하브 에커' },
      { text: '현명한 사람은 돈을 벌면 먼저 저축하고 나머지로 생활한다.', author: '짐 론' },
      { text: '경제적 독립은 자유로운 삶의 초석이다.', author: '작자 미상' },
      { text: '지금 시작하지 않으면 1년 후에도 같은 자리에 있을 것이다.', author: '카렌 램' },
      { text: '부의 축적에서 가장 강력한 힘은 시간과 인내다.', author: '찰리 멍거' },
      { text: '재산을 지키는 것은 재산을 모으는 것보다 더 어렵다.', author: '오비디우스' },
      { text: '위험을 감수하지 않는 것이 가장 큰 위험이다.', author: '마크 저커버그' },
      { text: '성공은 매일 반복하는 작은 노력의 합이다.', author: '로버트 콜리어' },
      { text: '절약은 큰 수입이다.', author: '키케로' },
      { text: '당신의 순자산은 자존감이 아니다. 하지만 관리할 가치는 있다.', author: '수지 오먼' },
      { text: '미래는 오늘 우리가 무엇을 하느냐에 달려 있다.', author: '마하트마 간디' },
      { text: '부는 능력이 아니라 습관에서 온다.', author: '작자 미상' },
    ],
  });
  console.log('✓ Daily quotes seeded (31)');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
