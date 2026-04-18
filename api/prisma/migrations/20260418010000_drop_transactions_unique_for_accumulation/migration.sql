-- 누적 입력 방식으로 전환: 같은 (month, type, category, subCategory) 조합도
-- 여러 행을 허용한다. 기존 unique 제약을 제거.
DROP INDEX IF EXISTS "transactions_user_id_type_target_month_category_sub_category_key";
