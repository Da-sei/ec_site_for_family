-- CreateTable
CREATE TABLE "WishlistItems" (
    "id" SERIAL NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "requesterId" INTEGER NOT NULL,
    "groupId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "WishlistItems_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "WishlistItems_requesterId_groupId_idx" ON "WishlistItems"("requesterId", "groupId");

-- AddForeignKey
ALTER TABLE "WishlistItems" ADD CONSTRAINT "WishlistItems_requesterId_fkey" FOREIGN KEY ("requesterId") REFERENCES "Users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WishlistItems" ADD CONSTRAINT "WishlistItems_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "Groups"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
