# Saxovat Kassa

Bar uchun sodda va chiroyli kassa (POS) tizimi. Flutter Web'da yozilgan,
brauzerda ishlaydi, internetsiz ham ishlayveradi.

Bitta kassir uchun mo'ljallangan: parol bilan kiriladi, qaysi stol nima
zakaz qilgani belgilanadi, oxirida umumiy summa ko'rsatiladi, to'lov qabul
qilingach stol yopiladi va chek tarixda saqlanib qoladi.

Ichidagi stollar va menyu - shunchaki namuna. Ularni o'chirib, barning
o'z stollari va o'z mahsulotlarini kiritish mumkin: stolni o'chirish
kartadagi uch nuqta orqali, mahsulotni o'chirish menyudagi savat belgisi
orqali, kategoriyani o'chirish esa undagi barcha mahsulotlar bilan birga
bajariladi.

---

## Kirish paroli

Boshlang'ich parol: **1234**

Parolni `Sozlama -> Kirish paroli` bo'limidan o'zgartirish mumkin.

---

## Nimalar bor

**Stollar**
- Zonalar bo'yicha ajratilgan stollar (Zal, Terassa, VIP, Bar)
- Stol qo'shish, nomini/zonasini/sig'imini tahrirlash, o'chirish
- **Bir vaqtda ko'p stol qo'shish**: nomni ("Stol") va sonini (masalan 20)
  kiritsangiz, "Stol 1 ... Stol 20" avtomatik yaratiladi
- Band stol oltin rangda ajralib turadi: qancha vaqtdan beri ochiq,
  nechta mahsulot va joriy summa ko'rinadi
- Buyurtmani boshqa bo'sh stolga ko'chirish

**Buyurtma**
- Kategoriyalar va qidiruv orqali mahsulot tanlash
- Bosilganda 1 dona qo'shiladi, uzoq bosilsa miqdorni tanlash oynasi ochiladi
- Miqdorni +/- bilan o'zgartirish, chapga surib o'chirish
- Har bir qatorga izoh yozish ("muzsiz", "achchiq emas" va h.k.)
- Jami summa doim ko'rinib turadi

**To'lov**
- Chegirma: 5% / 10% / 15% / 20% / 30%
- To'lov turi: Naqd, Karta, Click/Payme
- Naqd to'lovda mijoz bergan pul kiritiladi va **qaytim** avtomatik hisoblanadi
- Tayyor summa tugmalari (aniq summa, 10 mingga, 50 mingga, 100 mingga yaxlitlash)
- To'lovdan keyin chek ko'rsatiladi va stol avtomatik bo'shaydi

**Menyu**
- Kategoriya va mahsulot qo'shish / tahrirlash / o'chirish
- Mahsulot qo'shish oynasidan turib ham yangi kategoriya yaratsa bo'ladi
- Kategoriya o'chirilsa, undagi mahsulotlar ham o'chadi
- Har bir mahsulotga belgi (ikonka) tanlash
- Narx kiritilayotganda raqamlar avtomatik "25 000" ko'rinishida ajratiladi

**Hisobot**
- Bugun / Kecha / 7 kun / Oy / Hammasi bo'yicha filtr
- Umumiy tushum, cheklar soni, o'rtacha chek, naqd va karta bo'yicha bo'linish
- Har bir chekni ochib ko'rish yoki o'chirish

**Xavfsizlik**
- Raqamli parol (PIN) bilan kirish
- 5 marta xato terilsa, kutish vaqti boshlanadi (30 s, keyin uzayib boradi)
- **Avtomatik qulflash** - kassa belgilangan vaqt tegilmasa (boshlang'ich
  qiymat 10 daqiqa) o'zi parol ekraniga qaytadi. Ochiq buyurtmalar
  saqlanib qoladi, hech narsa yo'qolmaydi. `Sozlama` dan o'chirish yoki
  vaqtini o'zgartirish mumkin.

**Sozlama**
- Muassasa nomi
- Xizmat haqi foizi (0% dan 15% gacha) - har bir chekka avtomatik qo'shiladi
- Parolni o'zgartirish
- Bulutga ulanish holati va qurilmani ulash/uzish

---

## Ishga tushirish

Dasturchi rejimida (o'zgartirish kiritish uchun):

```bash
flutter run -d chrome
```

Tayyor versiyani yig'ish:

```bash
flutter build web --release --dart-define-from-file=env.json
```

(Bulutsiz, faqat lokal versiya kerak bo'lsa `--dart-define-from-file` siz.)

Natija `build/web/` papkasida bo'ladi. Uni istalgan statik hostingga
(Netlify, Vercel, GitHub Pages, oddiy nginx) qo'yish mumkin.

Kompyuterda mahalliy sinab ko'rish uchun:

```bash
python3 -m http.server 8080 --directory build/web
```

So'ng brauzerda `http://localhost:8080` ni ochish kerak.
(Fayllarni to'g'ridan-to'g'ri `file://` orqali ochish ishlamaydi - server kerak.)

Testlarni ishga tushirish:

```bash
flutter test
```

---

## Ma'lumotlar qayerda saqlanadi

Ilova **avval lokal** tartibida ishlaydi:

1. Har qanday o'zgarish darhol qurilmaning o'z bazasiga yoziladi -
   shuning uchun ekran hech qachon kutib turmaydi.
2. Keyin fonda Supabase bazasiga yuboriladi.

Qurilmada ikki joyda saqlanadi:

| Nima | Qayerda | Nega |
|---|---|---|
| Stollar, menyu, sozlamalar | localStorage (~5 KB) | kichik, tez-tez o'zgaradi |
| **Cheklar arxivi** | **IndexedDB** | hajm chegarasi yo'q, cheklanmaydi |

Cheklar alohida bazada turgani muhim: localStorage'da ular ~2-3 oydan keyin
5 MB limitiga urilardi, ustiga har bir yangi buyurtma qatoriga butun arxiv
qayta yozilib, kassa sekinlashardi. IndexedDB'da esa **hech qanday cheklov
yo'q** - yangi chek qo'shilganda faqat o'sha bitta yozuv yoziladi, eski
cheklar joyida qoladi.

Internet uzilsa kassa ishlashda davom etadi, o'zgarishlar navbatda turadi
va ulanish tiklanishi bilan avtomatik yuboriladi. Yuqori panelda holat
ko'rinib turadi:

| Belgi | Ma'nosi |
|---|---|
| Bulutda saqlangan | hammasi yuborilgan |
| Saqlanmoqda... | ayni damda yuborilyapti |
| Ulanish yo'q | internet yo'q, keyin yuboriladi |
| Bulutga ulanmagan | qurilma hali ulanmagan |

Bazada ikkita jadval bor:

- `kassa_state` - stollar, menyu, kategoriyalar va sozlamalar (bitta qator)
- `receipts` - yopilgan cheklar (har biri alohida qator, cheklovsiz)

Cheklar alohida jadvalda turgani uchun hisobotlarni to'g'ridan-to'g'ri SQL
bilan olish mumkin (namunalari `supabase/schema.sql` oxirida).

Agar Supabase kalitlari berilmasa, ilova avvalgidek faqat shu brauzerda
ishlayveradi - hech narsa buzilmaydi.

---

## Supabase'ni sozlash

**1. Loyiha yarating**

[supabase.com](https://supabase.com) -> `New project`. Nomi: `saxovat-kassa`,
region sifatida eng yaqinini tanlang (masalan Frankfurt). Baza parolini
saqlab qo'ying.

**2. Jadvallarni yarating**

Supabase panelida `SQL Editor` -> `New query`. Shu repodagi
`supabase/schema.sql` faylini to'liq nusxalab qo'ying va `Run` bosing.
Bu jadvallarni, indekslarni va xavfsizlik qoidalarini (RLS) yaratadi.

**3. Kassa foydalanuvchisini yarating**

`Authentication` -> `Users` -> `Add user` -> `Create new user`:

- Email: masalan `kassa@saxovatbar.uz`
- Password: kuchli parol
- **`Auto Confirm User` ni yoqing** (aks holda email tasdiqlash talab qilinadi)

Bu hisob bilan qurilma bir marta ulanadi. Kundalik ishda esa oddiy
raqamli parol (PIN) ishlatiladi.

**4. Kalitlarni oling**

`Project Settings` -> `API`:

- `Project URL`
- `anon public` (yangi panelda `publishable`) kalit

> `service_role` kalitini ASLO ishlatmang - u to'liq huquqli va veb-ilovaga
> qo'yilmaydi. `anon` kalit ochiq bo'lishi normal: himoya RLS qoidalari va
> foydalanuvchi kirishi orqali ta'minlanadi.

**6. Ochiq ro'yxatdan o'tishni o'chiring (MUHIM)**

`Authentication` -> `Sign In / Providers` -> `Email` -> **"Allow new users
to sign up"** ni o'chiring.

Bu qadam majburiy: `anon` kalit sayt kodida ochiq turadi, shuning uchun
ro'yxatdan o'tish yoqiq qolsa, istalgan odam o'ziga hisob ochib bazaga
kira olardi.

**7. Qoidalarni qattiqlashtiring**

`SQL Editor` da `supabase/harden.sql` ni ishga tushiring. U ruxsat
berilgan foydalanuvchilar ro'yxatini yaratadi va huquqni "kirgan har
qanday odam" dan "ro'yxatdagi odam" ga toraytiradi.

**5. Lokalda sinab ko'ring**

`env.example.json` dan nusxa olib `env.json` yarating:

```bash
cp env.example.json env.json
```

Ichidagi qiymatlarni o'zingiznikiga almashtiring, so'ng:

```bash
flutter run -d chrome --dart-define-from-file=env.json
```

`env.json` git'ga tushmaydi (`.gitignore` da).

---

## Vercel'ga deploy qilish

### A varianti - GitHub orqali (tavsiya etiladi)

1. Kodni GitHub repozitoriysiga yuklang.
2. [vercel.com](https://vercel.com) -> `Add New` -> `Project` -> reponi tanlang.
3. `Environment Variables` bo'limiga ikkita o'zgaruvchi qo'shing:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
4. `Deploy` bosing.

Qolgan sozlamalar `vercel.json` da yozilgan - Vercel Flutter'ni o'zi yuklab
olib, `build/web` ni chiqaradi. **Birinchi build 3-5 daqiqa oladi**
(Flutter yuklanadi), keyingilari tezroq. Shundan keyin har `git push`
avtomatik yangi deploy bo'ladi.

### B varianti - CLI orqali

```bash
npm i -g vercel
vercel login
vercel link
vercel env add SUPABASE_URL
vercel env add SUPABASE_ANON_KEY
vercel --prod
```

### Deploydan keyin

Saytni oching -> **Qurilmani ulash** oynasi chiqadi -> Supabase'da
yaratgan email va parolni kiriting -> `Ulash`. Bu bir martalik amal:
keyingi safar to'g'ridan-to'g'ri PIN so'raladi.

So'ng PIN bilan kiring (boshlang'ich: `1234`) va uni
`Sozlama -> Kirish paroli` dan o'zgartiring.

---

## Loyiha tuzilishi

```
lib/
  main.dart                    ilova kirish nuqtasi
  src/
    models.dart                MenuItem, OrderLine, BarTable, Receipt, AppSettings
    store.dart                 barcha holat + brauzer xotirasiga saqlash
    theme.dart                 ranglar va umumiy dizayn
    icons.dart                 mahsulot belgilari ro'yxati
    utils.dart                 summa/sana formatlash
    data/
      receipt_db.dart          cheklar arxivi (IndexedDB)
      idb_factory_web.dart     brauzer uchun baza
      idb_factory_stub.dart    testlar uchun xotiradagi baza
    sync/
      supabase_config.dart     build vaqtidagi kalitlar
      sync_service.dart        bulut bilan sinxronizatsiya
    widgets/
      common.dart              karta, chip, bo'sh holat, dialog yordamchilari
      receipt_view.dart        chek ko'rinishi
    screens/
      login_screen.dart        parol kiritish
      link_screen.dart         qurilmani bulutga ulash
      home_screen.dart         asosiy ramka va navigatsiya
      tables_page.dart         stollar ro'yxati
      order_screen.dart        buyurtma va to'lov
      menu_page.dart           menyu boshqaruvi
      history_page.dart        hisobot va cheklar
      settings_page.dart       sozlamalar
supabase/
  schema.sql                   baza jadvallari va xavfsizlik qoidalari
  harden.sql                   huquqlarni ruxsat ro'yxati bilan cheklash
scripts/
  vercel-build.sh              Vercel uchun build skripti
vercel.json                    deploy sozlamalari
test/
  store_test.dart              biznes mantiq testlari
```
