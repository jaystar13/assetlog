/*
  Warnings:

  - You are about to drop the `invitations` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `shared_access` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "invitations" DROP CONSTRAINT "invitations_from_user_id_fkey";

-- DropForeignKey
ALTER TABLE "shared_access" DROP CONSTRAINT "shared_access_owner_user_id_fkey";

-- DropForeignKey
ALTER TABLE "shared_access" DROP CONSTRAINT "shared_access_shared_with_user_id_fkey";

-- DropTable
DROP TABLE "invitations";

-- DropTable
DROP TABLE "shared_access";

-- CreateTable
CREATE TABLE "share_groups" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "created_by_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "share_groups_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "share_group_members" (
    "id" TEXT NOT NULL,
    "group_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'viewer',
    "joined_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "share_group_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "shared_items" (
    "id" TEXT NOT NULL,
    "group_id" TEXT NOT NULL,
    "owner_user_id" TEXT NOT NULL,
    "item_type" TEXT NOT NULL,
    "item_id" TEXT NOT NULL,
    "permission" TEXT NOT NULL DEFAULT 'view',
    "shared_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "shared_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "group_invitations" (
    "id" TEXT NOT NULL,
    "group_id" TEXT NOT NULL,
    "invited_by_id" TEXT NOT NULL,
    "to_email" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'viewer',
    "status" TEXT NOT NULL DEFAULT 'pending',
    "message" TEXT,
    "sent_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "group_invitations_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "share_groups_created_by_id_idx" ON "share_groups"("created_by_id");

-- CreateIndex
CREATE INDEX "share_group_members_user_id_idx" ON "share_group_members"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "share_group_members_group_id_user_id_key" ON "share_group_members"("group_id", "user_id");

-- CreateIndex
CREATE INDEX "shared_items_group_id_item_type_idx" ON "shared_items"("group_id", "item_type");

-- CreateIndex
CREATE INDEX "shared_items_owner_user_id_idx" ON "shared_items"("owner_user_id");

-- CreateIndex
CREATE INDEX "shared_items_item_id_idx" ON "shared_items"("item_id");

-- CreateIndex
CREATE UNIQUE INDEX "shared_items_group_id_item_type_item_id_key" ON "shared_items"("group_id", "item_type", "item_id");

-- CreateIndex
CREATE INDEX "group_invitations_to_email_idx" ON "group_invitations"("to_email");

-- CreateIndex
CREATE INDEX "group_invitations_group_id_idx" ON "group_invitations"("group_id");

-- AddForeignKey
ALTER TABLE "share_groups" ADD CONSTRAINT "share_groups_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "share_group_members" ADD CONSTRAINT "share_group_members_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "share_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "share_group_members" ADD CONSTRAINT "share_group_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shared_items" ADD CONSTRAINT "shared_items_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "share_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shared_items" ADD CONSTRAINT "shared_items_owner_user_id_fkey" FOREIGN KEY ("owner_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "group_invitations" ADD CONSTRAINT "group_invitations_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "share_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "group_invitations" ADD CONSTRAINT "group_invitations_invited_by_id_fkey" FOREIGN KEY ("invited_by_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
