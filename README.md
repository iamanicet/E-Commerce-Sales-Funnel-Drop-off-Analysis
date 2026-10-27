# E-Commerce-Sales-Funnel-Drop-off-Analysis
An end-to-end data analytics project evaluating user conversion behavior, identifying critical drop-off bottlenecks, and delivering executive-level solutions to optimize revenue generation across an e-commerce platform.
# E-Commerce Sales Funnel Drop-off Analysis

**Tools:** MySQL 8.0 · MySQL Workbench
**Author:** Anicet Baraka Ciza · GitHub: [iamanicet](https://github.com/iamanicet)

Only 0.50% of the 90,400 visitors in this dataset buy anything. I analysed a four-stage sales funnel in SQL to find where users drop off, whether device or gender changes the picture, and whether anything shifted over time. The headline finding: **purchases fell by 75% on 1 March 2015 with no change in traffic**, and the funnel has a permanent weak spot on Desktop, which converts at a quarter of Mobile's rate.

---

## 1. Business problem

An e-commerce company brings in traffic but converts very little of it. The questions I set out to answer:

1. Where does the funnel lose the most users, and at which stage is the loss most costly?
2. Do users on different devices (Desktop vs Mobile) or of different genders behave differently?
3. Did conversion change over time, and if so, when?
4. What is each fix worth in extra purchases?

## 2. Dataset

Five CSV files loaded into a MySQL database called `sales_analysis`. Each table holds one row per user.

| Table | Rows | Columns |
|---|---|---|
| `user_table` | 90,400 | `user_id`, `date` (first visit, Jan–Apr 2015), `device` (Desktop/Mobile), `sex` (Male/Female) |
| `home_page_table` | 90,400 | `user_id`, `page` |
| `search_page_table` | 45,200 | `user_id`, `page` |
| `payment_page_table` | 6,030 | `user_id`, `page` |
| `payment_confirmation_table` | 452 | `user_id`, `page` |

Funnel: **Home Page → Search Page → Payment Page → Payment Confirmation**

## 3. Repository structure

```
sales-funnel-analysis/
├── sql/
│   ├── 00_load_data.sql        # rebuilds the database from the CSVs
│   ├── 01_validation.sql       # data-quality checks
│   ├── 02_funnel_view.sql      # master view: one row per user, 0/1 stage flags
│   ├── 03_funnel_metrics.sql   # overall funnel metrics
│   ├── 04_segmentation.sql     # device, gender, device x gender
│   ├── 05_monthly_trend.sql    # monthly trend and the March 1 break
│   └── 06_impact_sizing.sql    # what each fix is worth
├── findings/                   # CSV exports of every result, plus the executive summary
└── README.md
```

**To reproduce:** copy the five CSVs into MySQL's `Uploads` folder, then run the scripts in numerical order.

## 4. Approach

I built a master view, `vw_funnel_master`, with one row per user and a 0/1 flag for each stage reached. Every later query reads from that view, so all the numbers share a single definition. A flag of 1 means the user reached that stage, so counting a stage is just adding up its flag, and a conversion rate is one stage's total divided by the previous stage's total.

SQL techniques used: CTEs, `LEFT JOIN`s, conditional aggregation, window functions (`LAG`, `FIRST_VALUE`, `SUM() OVER`), `NULLIF` for safe division, and views.

## 5. Data quality: a duplicate-rows problem I caught

My first segmentation results didn't add up. Mobile and Desktop together came to 130,606 users, but the source data has 90,400. The master view also returned 130,606 rows for only 90,400 distinct `user_id`s.

I narrowed it down by checking row counts against distinct counts per table, and by looking at how the extra rows were spread across funnel stages. They were spread evenly, so the duplicates had to be in a table that contains every user. It turned out that `home_page_table` held 130,606 rows for 90,400 users, almost certainly from a data load that had been run more than once. Because `LEFT JOIN`s multiply a user's row for every duplicate match, all my counts were inflated by about 1.45x.

**Fix:** I rebuilt the tables with `00_load_data.sql`, which drops and recreates each table before loading, and I put a `PRIMARY KEY` on `user_id` so MySQL rejects duplicates at load time. After the reload every table has exactly one row per user, and the numbers in this report tie out to the source files.

The lesson I took from it: always compare row counts with distinct counts before trusting a join.

## 6. Analysis and results

### 6.1 Overall funnel

*Query: `03_funnel_metrics.sql`*

| Stage | Users | Lost | Step conversion | Step drop-off | Cumulative | Share of total loss |
|---|---|---|---|---|---|---|
| Home Page | 90,400 | n/a | n/a | n/a | 100.00% | n/a |
| Search Page | 45,200 | 45,200 | 50.00% | 50.00% | 50.00% | 50.25% |
| Payment Page | 6,030 | 39,170 | 13.34% | 86.66% | 6.67% | 43.55% |
| Payment Confirmation | 452 | 5,578 | 7.50% | 92.50% | 0.50% | 6.20% |

**Technical notes.** `LAG()` brings the previous stage's user count onto each row, and `FIRST_VALUE()` brings the 90,400 starting users, which gives step and cumulative conversion without a self-join. Home to Search is exactly 50.00%, which is too clean for real traffic, so I believe the dataset is simulated.

**Business recommendation.** About 1 in 200 visitors buys. Looking at volume and rate gives two different answers. By volume, Home to Search and Search to Payment together account for about 94% of all lost users. By rate, Payment to Confirmation is the worst step, with 92.5% abandoning. Fewer people are lost there, but they had already reached payment, so each is much closer to a sale.

**Strategic solutions.**
1. Fix payment abandonment first: look for forced account creation, missing guest checkout, limited payment methods, surprise fees and gateway errors, and send a cart-recovery message within an hour.
2. Improve Search to Payment (39,170 users): better search relevance, clearer prices and trust signals earlier, an easy path from results to cart.
3. Test a more visible search bar on the home page: half of visitors never search, and it is the cheapest test.
4. Size of the prize: lifting payment completion from 7.5% to 15% would double purchases from 452 to about 904.

### 6.2 Device

*Query: `04_segmentation.sql` (4A)*

| | Mobile | Desktop |
|---|---|---|
| Users (share of traffic) | 30,200 (33.4%) | 60,200 (66.6%) |
| Home to Search | 50.00% | 50.00% |
| Search to Payment | 20.00% | 10.00% |
| Payment to Confirmation | 10.00% | 4.98% |
| **Overall conversion** | **1.00%** | **0.25%** |
| Purchases (share) | 302 (66.8%) | 150 (33.2%) |

**Technical notes.** Two gaps of about 2x each, one at Search to Payment and one at Payment to Confirmation, compound into a 4x gap in overall conversion. Both devices send almost the same number of users to the payment page (3,020 vs 3,010) even though Desktop has twice the traffic.

**Business recommendation.** Desktop brings two-thirds of the traffic but only one-third of the purchases. That is the opposite of the usual industry pattern, where mobile converts worse, so the standard "fix mobile checkout" advice does not apply here. Desktop is the weak link.

**Strategic solutions.** Audit the Desktop checkout and payment flow step by step against Mobile's. Break Desktop traffic down by acquisition source to check for low-intent channels or bots. Until Desktop is fixed, shift acquisition spend toward Mobile, where each visitor is worth about four times as much.

### 6.3 Gender

*Query: `04_segmentation.sql` (4B, 4C)*

| | Female | Male |
|---|---|---|
| Users | 45,075 | 45,325 |
| Search to Payment | 13.67% | 13.01% |
| Payment to Confirmation | 7.77% | 7.20% |
| Overall conversion | 0.53% (241 purchases) | 0.47% (211 purchases) |

By device: on Desktop, Female and Male convert identically (0.25%). On Mobile, Female converts at 1.11% against 0.89% for Male.

**Technical notes.** I checked the gaps with two-proportion z-tests, run outside SQL. The overall gap is not statistically significant (p ≈ 0.14). The Search to Payment gap is borderline (p ≈ 0.04), but with several comparisons made I treat that as suggestive only. The Mobile gender gap has p ≈ 0.06.

**Business recommendation.** Gender is a minor factor. It explains far less than device or time, and I would not build a strategy on it.

**Strategic solutions.** If the company wants to follow it up, A/B test the Mobile payment experience and compare Female and Male completion rates. Otherwise the effort is better spent on the findings in 6.2 and 6.4.

### 6.4 Monthly trend: the main finding

*Query: `05_monthly_trend.sql`*

| Month | Home to Search | Search to Payment | Payment to Conf. | Overall | Purchases |
|---|---|---|---|---|---|
| Jan 2015 | 59.97% | 17.63% | 7.91% | 0.84% | 189 |
| Feb 2015 | 60.56% | 17.62% | 7.17% | 0.77% | 173 |
| **Mar 2015** | **39.29%** | **7.11%** | 6.97% | **0.19%** | 44 |
| **Apr 2015** | **40.18%** | **6.57%** | 7.71% | **0.20%** | 46 |

The same months by device:

| Month | Mobile: Home to Search | Mobile: Search to Payment | Desktop: Home to Search | Desktop: Search to Payment |
|---|---|---|---|---|
| Jan | 79.80% | 19.40% | 50.03% | 16.22% |
| Feb | 80.20% | 20.17% | 50.71% | 15.61% |
| Mar | **19.99%** | 22.20% | 48.97% | **4.02%** |
| Apr | **20.01%** | 19.52% | 50.29% | **3.99%** |

**Technical notes.**
- The break is abrupt and falls exactly on **1 March 2015**. On 28 February, 63.1% of visitors searched and 15.1% of searchers reached payment. On 1 March those figures were 39.2% and 6.7%.
- Traffic is constant at 22,600 users a month, so this is not a change in traffic mix.
- The flat 50% Home to Search figure in 6.1 was hiding a Mobile collapse, from about 80% down to 20%. The two devices broke at different stages: Mobile lost search engagement, and Desktop lost conversion from search to payment.
- Payment to Confirmation stayed roughly stable throughout.
- Months are first-visit cohorts, not purchase months.

**Business recommendation.** Purchases fell from 362 in January and February to 90 in March and April, a drop of 75% on identical traffic (p < 0.001). A step change on a single calendar date, on both devices, points to something that changed on or around 1 March: a release, a search or checkout redesign, a pricing change, or a tracking change. The data cannot tell me which.

**Strategic solutions.**
1. Find out what shipped on 1 March: site releases, search changes (especially on Mobile) and checkout changes (especially on Desktop), a promotion that ended, or analytics changes.
2. Confirm the drop is real and not a measurement artefact by checking it against orders in the transactional system.
3. If a release caused it, roll back or A/B test the previous experience.
4. Add a daily funnel monitor with alerts on step-rate changes, so a break like this is caught in days, not at quarter-end.

### 6.5 Impact sizing

*Query: `06_impact_sizing.sql`*

| Scenario | Purchases | Gain |
|---|---|---|
| Desktop Search to Payment matches Mobile (20%) | 150 → 300 | +150 |
| Desktop Payment to Confirmation matches Mobile (10%) | 150 → 301 | +151 |
| Desktop matches Mobile at both stages | 150 → 602 | **+452** |
| March–April restored to January–February conversion | 90 → 362 | **+272** (Mobile +194, Desktop +78) |

**Technical notes.** Each scenario applies a benchmark rate to the actual volume at that stage. The scenarios overlap, so their gains should not be added together.

**Business recommendation.** Closing the Desktop gap would roughly double company-wide purchases (452 to about 904) without any extra traffic. Reversing the March break is worth +272 purchases and, if it traces back to a specific change, is probably the faster fix. Most of that loss is on Mobile.

**Strategic solutions.** Investigate the 1 March change first, since it takes days and recovers up to 272 purchases. Run the Desktop checkout audit and traffic-source review in parallel. Multiply the gains by average order value for a revenue figure.

## 7. Key findings

1. Only **0.50%** of visitors buy (452 of 90,400).
2. The biggest absolute losses are at Home to Search and Search to Payment. The worst rate is at Payment to Confirmation (92.5% abandon).
3. **Mobile converts four times better than Desktop** (1.00% vs 0.25%), while Desktop supplies two-thirds of the traffic.
4. **Gender is a minor factor.** The overall difference is not statistically significant.
5. **Conversion collapsed on 1 March 2015**, with purchases down 75% on constant traffic. Mobile lost search engagement and Desktop lost search-to-payment conversion.

## 8. Recommendations (in priority order)

1. **Investigate and reverse the 1 March change.** Fastest route to recovering up to 272 purchases.
2. **Audit the Desktop checkout and payment flow** against Mobile, and review Desktop traffic sources for low-intent channels.
3. **Reduce payment abandonment:** guest checkout, more payment options, upfront costs and cart-recovery messages.
4. **Improve search-to-payment conversion:** relevance, clear prices and trust signals.
5. **Set up daily funnel monitoring** with step-rate alerts.

## 9. Limitations

- **There is no revenue or order value.** I sized impact in purchases, not money.
- **Dates are first-visit dates,** so months are cohorts, not purchase dates.
- **The analysis shows where users drop off, not why.** The March break and the Desktop gap need a human investigation to find causes.
- **The data looks simulated.** The exact 50.00% Home to Search rate and round segment sizes suggest it, so I treat this as a funnel-analysis exercise and not the performance of a real company.
- **Several statistical comparisons were made on gender,** so borderline p-values should be read cautiously.

## 10. Skills demonstrated

SQL (MySQL 8.0) · CTEs · window functions · conditional aggregation · views · data validation and debugging · funnel and cohort analysis · segmentation · impact sizing · translating results into business recommendations
