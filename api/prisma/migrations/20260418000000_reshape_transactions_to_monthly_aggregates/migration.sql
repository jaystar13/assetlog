-- 월별 (카테고리, 세부분류) 합계 모델로 재설계.
-- 기존 단건 거래 데이터는 전부 삭제하고 새로 시작 (사용자 승인됨).

-- 1) Transaction에 연결된 공유 항목 제거
DELETE FROM "shared_items" WHERE "item_type" = 'transaction';

-- 2) 기존 transactions 테이블 드롭
DROP TABLE IF EXISTS "transactions";

-- 3) 신규 transactions 테이블 생성
CREATE TABLE "transactions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "target_month" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "sub_category" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "note" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "transactions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex (unique: 같은 월·카테고리·세부분류 조합은 한 행만 존재)
CREATE UNIQUE INDEX "transactions_user_id_type_target_month_category_sub_category_key" ON "transactions"("user_id", "type", "target_month", "category", "sub_category");

-- CreateIndex
CREATE INDEX "transactions_user_id_target_month_idx" ON "transactions"("user_id", "target_month");

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
