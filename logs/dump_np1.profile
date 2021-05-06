(pprof) list main
Total: 42.10s
ROUTINE ======================== main.(*Renderer).Render in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      2.56s (flat, cum)  6.08% of Total
         .          .     41:type Renderer struct {
         .          .     42:   templates *template.Template
         .          .     43:}
         .          .     44:
         .          .     45:func (r *Renderer) Render(w io.Writer, name string, data interface{}, c echo.Context) error {
         .      2.56s     46:   return r.templates.ExecuteTemplate(w, name, data)
         .          .     47:}
         .          .     48:
         .          .     49:var ctx = context.Background()
         .          .     50:
         .          .     51:var rdb *redis.Client
ROUTINE ======================== main.addMessage in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      230ms (flat, cum)  0.55% of Total
         .          .    154:   }
         .          .    155:   return &u, nil
         .          .    156:}
         .          .    157:
         .          .    158:func addMessage(channelID, userID int64, content string) (int64, error) {
         .      230ms    159:   res, err := db.Exec(
         .          .    160:           "INSERT INTO message (channel_id, user_id, content, created_at) VALUES (?, ?, ?, NOW())",
         .          .    161:           channelID, userID, content)
         .          .    162:   if err != nil {
         .          .    163:           return 0, err
         .          .    164:   }
ROUTINE ======================== main.ensureLogin in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      1.33s (flat, cum)  3.16% of Total
         .          .    201:           goto redirect
         .          .    202:   }
         .          .    203:
         .          .    204:   user, err = getUser(userID)
         .          .    205:   if err != nil {
         .      550ms    206:           return nil, err
         .          .    207:   }
         .          .    208:   if user == nil {
         .          .    209:           sess, _ := session.Get("session", c)
         .          .    210:           delete(sess.Values, "user_id")
         .      780ms    211:           sess.Save(c.Request(), c.Response())
         .          .    212:           goto redirect
         .          .    213:   }
         .          .    214:   return user, nil
         .          .    215:
         .          .    216:redirect:
ROUTINE ======================== main.fetchUnread in /home/isucon/isubata/webapp/go/src/isubata/app.go
      10ms     11.56s (flat, cum) 27.46% of Total
         .          .    514:   resp := []map[string]interface{}{}
         .          .    515:
         .          .    516:   for _, chID := range channels {
         .          .    517:           lastID, err := queryHaveRead(userID, chID)
         .          .    518:           if err != nil {
         .      100ms    519:                   return err
         .          .    520:           }
         .          .    521:
         .          .    522:           var cnt int64
         .          .    523:           if lastID > 0 {
         .       10ms    524:                   err = db.Get(&cnt,
         .          .    525:                           "SELECT COUNT(*) as cnt FROM message WHERE channel_id = ? AND ? < id",
         .      100ms    526:                           chID, lastID)
         .          .    527:           } else {
         .          .    528:                   err = db.Get(&cnt,
         .          .    529:                           "SELECT COUNT(*) as cnt FROM message WHERE channel_id = ?",
         .          .    530:                           chID)
         .          .    531:           }
         .          .    532:           if err != nil {
      10ms       10ms    533:                   return err
         .      5.44s    534:           }
         .          .    535:           r := map[string]interface{}{
         .          .    536:                   "channel_id": chID,
         .          .    537:                   "unread":     cnt}
         .          .    538:           resp = append(resp, r)
         .       10ms    539:   }
         .          .    540:
         .       60ms    541:   return c.JSON(http.StatusOK, resp)
         .          .    542:}
         .          .    543:
         .          .    544:func getHistory(c echo.Context) error {
         .      5.71s    545:   chID, err := strconv.ParseInt(c.Param("channel_id"), 10, 64)
         .          .    546:   if err != nil || chID <= 0 {
         .          .    547:           return ErrBadReqeust
         .          .    548:   }
         .          .    549:
         .          .    550:   user, err := ensureLogin(c)
         .          .    551:   if user == nil {
         .       50ms    552:           return err
         .          .    553:   }
         .          .    554:
         .          .    555:   var page int64
         .          .    556:   pageStr := c.QueryParam("page")
         .          .    557:   if pageStr == "" {
         .       70ms    558:           page = 1
         .          .    559:   } else {
         .          .    560:           page, err = strconv.ParseInt(pageStr, 10, 64)
         .          .    561:           if err != nil || page < 1 {
         .          .    562:                   return ErrBadReqeust
         .          .    563:           }
ROUTINE ======================== main.getChannel in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      1.20s (flat, cum)  2.85% of Total
         .          .    280:           return err
         .          .    281:   }
         .          .    282:   cID, err := strconv.Atoi(c.Param("channel_id"))
         .          .    283:   if err != nil {
         .          .    284:           return err
         .      170ms    285:   }
         .          .    286:   channels := []ChannelInfo{}
         .          .    287:   err = db.Select(&channels, "SELECT * FROM channel ORDER BY id")
         .          .    288:   if err != nil {
         .       10ms    289:           return err
         .          .    290:   }
         .          .    291:
         .          .    292:   var desc string
         .          .    293:   for _, ch := range channels {
         .      300ms    294:           if ch.ID == int64(cID) {
         .          .    295:                   desc = ch.Description
         .          .    296:                   break
         .          .    297:           }
         .          .    298:   }
         .          .    299:   return c.Render(http.StatusOK, "channel", map[string]interface{}{
         .          .    300:           "ChannelID":   cID,
         .          .    301:           "Channels":    channels,
         .          .    302:           "User":        user,
         .          .    303:           "Description": desc,
         .          .    304:   })
         .          .    305:}
         .      720ms    306:
         .          .    307:func getRegister(c echo.Context) error {
         .          .    308:   return c.Render(http.StatusOK, "register", map[string]interface{}{
         .          .    309:           "ChannelID": 0,
         .          .    310:           "Channels":  []ChannelInfo{},
         .          .    311:           "User":      nil,
ROUTINE ======================== main.getHistory in /home/isucon/isubata/webapp/go/src/isubata/app.go
      10ms      3.94s (flat, cum)  9.36% of Total
         .          .    562:                   return ErrBadReqeust
         .          .    563:           }
         .          .    564:   }
         .          .    565:
         .          .    566:   const N = 20
         .      370ms    567:   var cnt int64
         .          .    568:   err = db.Get(&cnt, "SELECT COUNT(*) as cnt FROM message WHERE channel_id = ?", chID)
         .          .    569:   if err != nil {
         .          .    570:           return err
         .          .    571:   }
         .          .    572:   maxPage := int64(cnt+N-1) / N
         .       10ms    573:   if maxPage == 0 {
         .          .    574:           maxPage = 1
         .          .    575:   }
         .          .    576:   if page > maxPage {
         .          .    577:           return ErrBadReqeust
         .          .    578:   }
         .          .    579:
         .          .    580:   messages := []Message{}
         .          .    581:   err = db.Select(&messages,
         .          .    582:           "SELECT * FROM message WHERE channel_id = ? ORDER BY id DESC LIMIT ? OFFSET ?",
         .          .    583:           chID, N, (page-1)*N)
         .          .    584:   if err != nil {
         .      150ms    585:           return err
         .          .    586:   }
         .          .    587:
         .          .    588:   mjson := make([]map[string]interface{}, 0)
         .          .    589:   for i := len(messages) - 1; i >= 0; i-- {
         .          .    590:           r, err := jsonifyMessage(messages[i])
         .          .    591:           if err != nil {
         .          .    592:                   return err
         .          .    593:           }
         .          .    594:           mjson = append(mjson, r)
         .          .    595:   }
         .          .    596:
         .          .    597:   channels := []ChannelInfo{}
         .      200ms    598:   err = db.Select(&channels, "SELECT * FROM channel ORDER BY id")
         .          .    599:   if err != nil {
         .          .    600:           return err
         .          .    601:   }
         .          .    602:
         .          .    603:   return c.Render(http.StatusOK, "history", map[string]interface{}{
         .          .    604:           "ChannelID": chID,
         .          .    605:           "Channels":  channels,
         .          .    606:           "Messages":  mjson,
         .      1.22s    607:           "MaxPage":   maxPage,
         .          .    608:           "Page":      page,
         .          .    609:           "User":      user,
         .          .    610:   })
         .          .    611:}
         .          .    612:
         .          .    613:func getProfile(c echo.Context) error {
         .          .    614:   self, err := ensureLogin(c)
         .      520ms    615:   if self == nil {
         .          .    616:           return err
      10ms       10ms    617:   }
         .          .    618:
         .          .    619:   channels := []ChannelInfo{}
         .      1.46s    620:   err = db.Select(&channels, "SELECT * FROM channel ORDER BY id")
         .          .    621:   if err != nil {
         .          .    622:           return err
         .          .    623:   }
         .          .    624:
         .          .    625:   userName := c.Param("user_name")
ROUTINE ======================== main.getIcon in /home/isucon/isubata/webapp/go/src/isubata/app.go
      10ms      970ms (flat, cum)  2.30% of Total
         .          .    759:           mime = "image/jpeg"
         .          .    760:   case strings.HasSuffix(name, ".png"):
         .          .    761:           mime = "image/png"
         .          .    762:   case strings.HasSuffix(name, ".gif"):
         .          .    763:           mime = "image/gif"
      10ms       10ms    764:   default:
         .          .    765:           return echo.ErrNotFound
         .          .    766:   }
         .      930ms    767:   return c.Blob(http.StatusOK, mime, data)
         .          .    768:}
         .          .    769:
         .          .    770:func tAdd(a, b int64) int64 {
         .          .    771:   return a + b
         .          .    772:}
         .          .    773:
         .          .    774:func tRange(a, b int64) []int64 {
         .          .    775:   r := make([]int64, b-a+1)
         .          .    776:   for i := int64(0); i <= (b - a); i++ {
         .          .    777:           r[i] = a + i
         .          .    778:   }
         .          .    779:   return r
         .          .    780:}
         .          .    781:
         .          .    782:func main() {
         .          .    783:   go func() {
         .       30ms    784:           log.Println(http.ListenAndServe(":6060", nil))
         .          .    785:   }()
         .          .    786:
         .          .    787:   e := echo.New()
         .          .    788:   funcs := template.FuncMap{
         .          .    789:           "add":    tAdd,
ROUTINE ======================== main.getKey in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      930ms (flat, cum)  2.21% of Total
         .          .    118:   log.Printf("Save %d images", len(imgs))
         .          .    119:   return nil
         .          .    120:}
         .          .    121:
         .          .    122:func getKey(key string, ctx context.Context) ([]byte, error) {
         .      930ms    123:   res, err := rdb.Get(ctx, key).Bytes()
         .          .    124:   if err != nil {
         .          .    125:           return nil, err
         .          .    126:   }
         .          .    127:   return res, nil
         .          .    128:}
ROUTINE ======================== main.getLogout in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       80ms (flat, cum)  0.19% of Total
         .          .    368:   sess.Save(c.Request(), c.Response())
         .          .    369:   return c.Redirect(http.StatusSeeOther, "/")
         .          .    370:}
         .          .    371:
         .          .    372:func postMessage(c echo.Context) error {
         .       70ms    373:   user, err := ensureLogin(c)
         .          .    374:   if user == nil {
         .       10ms    375:           return err
         .          .    376:   }
         .          .    377:
         .          .    378:   message := c.FormValue("message")
         .          .    379:   if message == "" {
         .          .    380:           return echo.ErrForbidden
ROUTINE ======================== main.getMessage in /home/isucon/isubata/webapp/go/src/isubata/app.go
      10ms      790ms (flat, cum)  1.88% of Total
         .          .    416:           return c.NoContent(http.StatusForbidden)
         .          .    417:   }
         .          .    418:
         .          .    419:   chanID, err := strconv.ParseInt(c.QueryParam("channel_id"), 10, 64)
         .          .    420:   if err != nil {
         .      120ms    421:           return err
         .          .    422:   }
         .          .    423:   lastID, err := strconv.ParseInt(c.QueryParam("last_message_id"), 10, 64)
         .          .    424:   if err != nil {
         .          .    425:           return err
         .          .    426:   }
         .          .    427:
         .          .    428:   type MessageWithUser struct {
         .          .    429:           ID              int64     `db:"id"`
         .          .    430:           Content         string    `db:"content"`
         .          .    431:           CreatedAt       time.Time `db:"created_at"`
         .          .    432:           UserName        string    `db:"name"`
         .          .    433:           UserDisplayName string    `db:"display_name"`
         .          .    434:           UserAvatarIcon  string    `db:"avatar_icon"`
         .          .    435:   }
         .          .    436:
         .          .    437:   messages := []MessageWithUser{}
         .          .    438:
         .          .    439:   err = db.Select(&messages, "SELECT m.id, m.content, m.created_at, u.name, u.display_name, u.avatar_icon FROM message m INNER JOIN user u ON u.id = m.user_id WHERE m.id > ? AND m.channel_id = ? ORDER BY m.id DESC LIMIT 100", lastID, chanID)
         .          .    440:
         .          .    441:   if err != nil {
         .          .    442:           return err
         .          .    443:   }
         .          .    444:
         .          .    445:   response := make([]map[string]interface{}, 0)
         .          .    446:   for i := len(messages) - 1; i >= 0; i-- {
         .      280ms    447:           m := messages[i]
         .          .    448:           r := make(map[string]interface{})
         .          .    449:           r["id"] = m.ID
      10ms       10ms    450:           r["user"] = User{
         .          .    451:                   Name:        m.UserName,
         .          .    452:                   DisplayName: m.UserDisplayName,
         .          .    453:                   AvatarIcon:  m.UserAvatarIcon,
         .          .    454:           }
         .          .    455:           r["date"] = m.CreatedAt.Format("2006/01/02 15:04:05")
         .          .    456:           r["content"] = m.Content
         .          .    457:
         .          .    458:           response = append(response, r)
         .          .    459:   }
         .          .    460:
         .          .    461:   if len(messages) > 0 {
         .          .    462:           _, err := db.Exec("INSERT INTO haveread (user_id, channel_id, message_id, updated_at, created_at)"+
         .       60ms    463:                   " VALUES (?, ?, ?, NOW(), NOW())"+
         .          .    464:                   " ON DUPLICATE KEY UPDATE message_id = ?, updated_at = NOW()",
         .          .    465:                   userID, chanID, messages[0].ID, messages[0].ID)
         .          .    466:           if err != nil {
         .          .    467:                   return err
         .          .    468:           }
         .       10ms    469:   }
         .          .    470:
         .          .    471:   return c.JSON(http.StatusOK, response)
         .          .    472:}
         .          .    473:
         .          .    474:func queryChannels() ([]int64, error) {
         .          .    475:   res := []int64{}
         .          .    476:   err := db.Select(&res, "SELECT id FROM channel")
         .          .    477:   return res, err
         .          .    478:}
         .       90ms    479:
         .          .    480:func queryHaveRead(userID, chID int64) (int64, error) {
         .          .    481:   type HaveRead struct {
         .          .    482:           UserID    int64     `db:"user_id"`
         .          .    483:           ChannelID int64     `db:"channel_id"`
         .          .    484:           MessageID int64     `db:"message_id"`
         .          .    485:           UpdatedAt time.Time `db:"updated_at"`
         .          .    486:           CreatedAt time.Time `db:"created_at"`
         .          .    487:   }
         .      220ms    488:   h := HaveRead{}
         .          .    489:
         .          .    490:   err := db.Get(&h, "SELECT * FROM haveread WHERE user_id = ? AND channel_id = ?",
         .          .    491:           userID, chID)
         .          .    492:
         .          .    493:   if err == sql.ErrNoRows {
ROUTINE ======================== main.getProfile in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      1.15s (flat, cum)  2.73% of Total
         .          .    626:   var other User
         .          .    627:   err = db.Get(&other, "SELECT * FROM user WHERE name = ?", userName)
         .          .    628:   if err == sql.ErrNoRows {
         .          .    629:           return echo.ErrNotFound
         .          .    630:   }
         .      230ms    631:   if err != nil {
         .          .    632:           return err
         .          .    633:   }
         .          .    634:
         .          .    635:   return c.Render(http.StatusOK, "profile", map[string]interface{}{
         .          .    636:           "ChannelID":   0,
         .      200ms    637:           "Channels":    channels,
         .          .    638:           "User":        self,
         .          .    639:           "Other":       other,
         .          .    640:           "SelfProfile": self.ID == other.ID,
         .          .    641:   })
         .          .    642:}
         .          .    643:
         .       90ms    644:func getAddChannel(c echo.Context) error {
         .          .    645:   self, err := ensureLogin(c)
         .          .    646:   if self == nil {
         .          .    647:           return err
         .          .    648:   }
         .          .    649:
         .          .    650:   channels := []ChannelInfo{}
         .          .    651:   err = db.Select(&channels, "SELECT * FROM channel ORDER BY id")
         .      630ms    652:   if err != nil {
         .          .    653:           return err
         .          .    654:   }
         .          .    655:
         .          .    656:   return c.Render(http.StatusOK, "add_channel", map[string]interface{}{
         .          .    657:           "ChannelID": 0,
ROUTINE ======================== main.getUser in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      780ms (flat, cum)  1.85% of Total
         .          .    144:   CreatedAt   time.Time `json:"-" db:"created_at"`
         .          .    145:}
         .          .    146:
         .          .    147:func getUser(userID int64) (*User, error) {
         .          .    148:   u := User{}
         .      780ms    149:   if err := db.Get(&u, "SELECT * FROM user WHERE id = ?", userID); err != nil {
         .          .    150:           if err == sql.ErrNoRows {
         .          .    151:                   return nil, nil
         .          .    152:           }
         .          .    153:           return nil, err
         .          .    154:   }
ROUTINE ======================== main.jsonifyMessage in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      1.22s (flat, cum)  2.90% of Total
         .          .    401:   if err != nil {
         .          .    402:           return nil, err
         .          .    403:   }
         .          .    404:
         .          .    405:   r := make(map[string]interface{})
         .      1.20s    406:   r["id"] = m.ID
         .          .    407:   r["user"] = u
         .          .    408:   r["date"] = m.CreatedAt.Format("2006/01/02 15:04:05")
         .          .    409:   r["content"] = m.Content
         .          .    410:   return r, nil
         .          .    411:}
         .          .    412:
         .       10ms    413:func getMessage(c echo.Context) error {
         .          .    414:   userID := sessUserID(c)
         .          .    415:   if userID == 0 {
         .       10ms    416:           return c.NoContent(http.StatusForbidden)
         .          .    417:   }
         .          .    418:
         .          .    419:   chanID, err := strconv.ParseInt(c.QueryParam("channel_id"), 10, 64)
         .          .    420:   if err != nil {
         .          .    421:           return err
ROUTINE ======================== main.main in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      550ms (flat, cum)  1.31% of Total
ROUTINE ======================== main.postAddChannel in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       10ms (flat, cum) 0.024% of Total
         .          .    676:           "INSERT INTO channel (name, description, updated_at, created_at) VALUES (?, ?, NOW(), NOW())",
         .          .    677:           name, desc)
         .          .    678:   if err != nil {
         .          .    679:           return err
         .          .    680:   }
         .       10ms    681:   lastID, _ := res.LastInsertId()
         .          .    682:   return c.Redirect(http.StatusSeeOther,
         .          .    683:           fmt.Sprintf("/channel/%v", lastID))
         .          .    684:}
         .          .    685:
         .          .    686:func postProfile(c echo.Context) error {
ROUTINE ======================== main.postLogin in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      940ms (flat, cum)  2.23% of Total
         .          .    345:   if name == "" || pw == "" {
         .          .    346:           return ErrBadReqeust
         .          .    347:   }
         .          .    348:
         .          .    349:   var user User
         .       80ms    350:   err := db.Get(&user, "SELECT * FROM user WHERE name = ?", name)
         .          .    351:   if err == sql.ErrNoRows {
         .          .    352:           return echo.ErrForbidden
         .          .    353:   } else if err != nil {
         .          .    354:           return err
         .          .    355:   }
         .          .    356:
         .      520ms    357:   digest := fmt.Sprintf("%x", sha1.Sum([]byte(user.Salt+pw)))
         .          .    358:   if digest != user.Password {
         .          .    359:           return echo.ErrForbidden
         .          .    360:   }
         .          .    361:   sessSetUserID(c, user.ID)
         .          .    362:   return c.Redirect(http.StatusSeeOther, "/")
         .          .    363:}
         .       20ms    364:
         .          .    365:func getLogout(c echo.Context) error {
         .          .    366:   sess, _ := session.Get("session", c)
         .          .    367:   delete(sess.Values, "user_id")
         .      320ms    368:   sess.Save(c.Request(), c.Response())
         .          .    369:   return c.Redirect(http.StatusSeeOther, "/")
         .          .    370:}
         .          .    371:
         .          .    372:func postMessage(c echo.Context) error {
         .          .    373:   user, err := ensureLogin(c)
ROUTINE ======================== main.postMessage in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      580ms (flat, cum)  1.38% of Total
         .          .    375:           return err
         .          .    376:   }
         .          .    377:
         .          .    378:   message := c.FormValue("message")
         .          .    379:   if message == "" {
         .      340ms    380:           return echo.ErrForbidden
         .          .    381:   }
         .          .    382:
         .          .    383:   var chanID int64
         .          .    384:   if x, err := strconv.Atoi(c.FormValue("channel_id")); err != nil {
         .       10ms    385:           return echo.ErrForbidden
         .          .    386:   } else {
         .          .    387:           chanID = int64(x)
         .          .    388:   }
         .          .    389:
         .          .    390:   if _, err := addMessage(chanID, user.ID, message); err != nil {
         .          .    391:           return err
         .          .    392:   }
         .          .    393:
         .          .    394:   return c.NoContent(204)
         .          .    395:}
         .          .    396:
         .      230ms    397:func jsonifyMessage(m Message) (map[string]interface{}, error) {
         .          .    398:   u := User{}
         .          .    399:   err := db.Get(&u, "SELECT name, display_name, avatar_icon FROM user WHERE id = ?",
         .          .    400:           m.UserID)
         .          .    401:   if err != nil {
         .          .    402:           return nil, err
ROUTINE ======================== main.postProfile in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      2.13s (flat, cum)  5.06% of Total
         .          .    699:   } else {
         .          .    700:           dotPos := strings.LastIndexByte(fh.Filename, '.')
         .          .    701:           if dotPos < 0 {
         .          .    702:                   return ErrBadReqeust
         .          .    703:           }
         .      210ms    704:           ext := fh.Filename[dotPos:]
         .          .    705:           switch ext {
         .          .    706:           case ".jpg", ".jpeg", ".png", ".gif":
         .          .    707:                   break
         .          .    708:           default:
         .          .    709:                   return ErrBadReqeust
         .          .    710:           }
         .          .    711:
         .      710ms    712:           file, err := fh.Open()
         .          .    713:           if err != nil {
         .          .    714:                   return err
         .          .    715:           }
         .          .    716:           avatarData, _ = ioutil.ReadAll(file)
         .          .    717:           file.Close()
         .          .    718:
         .          .    719:           if len(avatarData) > avatarMaxBytes {
         .          .    720:                   return ErrBadReqeust
         .          .    721:           }
         .          .    722:
         .          .    723:           avatarName = fmt.Sprintf("%x%s", sha1.Sum(avatarData), ext)
         .          .    724:   }
         .          .    725:
         .          .    726:   if avatarName != "" && len(avatarData) > 0 {
         .          .    727:           _, err := db.Exec("INSERT INTO image (name, data) VALUES (?, ?)", avatarName, avatarData)
         .          .    728:           if err != nil {
         .          .    729:                   return err
         .          .    730:           }
         .          .    731:           _, err = db.Exec("UPDATE user SET avatar_icon = ? WHERE id = ?", avatarName, self.ID)
         .          .    732:           if err != nil {
         .      460ms    733:                   return err
         .          .    734:           }
         .          .    735:   }
         .          .    736:
         .          .    737:   if name := c.FormValue("display_name"); name != "" {
         .          .    738:           _, err := db.Exec("UPDATE user SET display_name = ? WHERE id = ?", name, self.ID)
         .          .    739:           if err != nil {
         .      270ms    740:                   return err
         .          .    741:           }
         .          .    742:   }
         .          .    743:
         .      230ms    744:   return c.Redirect(http.StatusSeeOther, "/")
         .          .    745:}
         .          .    746:
         .          .    747:func getIcon(c echo.Context) error {
         .      100ms    748:
         .          .    749:   name := c.Param("file_name")
         .          .    750:   data, err := getKey(name, ctx)
         .          .    751:
         .          .    752:   if err != nil {
         .          .    753:           return err
         .          .    754:   }
         .      150ms    755:
         .          .    756:   mime := ""
         .          .    757:   switch true {
         .          .    758:   case strings.HasSuffix(name, ".jpg"), strings.HasSuffix(name, ".jpeg"):
         .          .    759:           mime = "image/jpeg"
         .          .    760:   case strings.HasSuffix(name, ".png"):
ROUTINE ======================== main.postRegister in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      300ms (flat, cum)  0.71% of Total
         .          .    318:   if name == "" || pw == "" {
         .          .    319:           return ErrBadReqeust
         .          .    320:   }
         .          .    321:   userID, err := register(name, pw)
         .          .    322:   if err != nil {
         .       20ms    323:           if merr, ok := err.(*mysql.MySQLError); ok {
         .          .    324:                   if merr.Number == 1062 { // Duplicate entry xxxx for key zzzz
         .          .    325:                           return c.NoContent(http.StatusConflict)
         .          .    326:                   }
         .          .    327:           }
         .      180ms    328:           return err
         .          .    329:   }
         .          .    330:   sessSetUserID(c, userID)
         .          .    331:   return c.Redirect(http.StatusSeeOther, "/")
         .          .    332:}
         .          .    333:
         .          .    334:func getLogin(c echo.Context) error {
         .          .    335:   return c.Render(http.StatusOK, "login", map[string]interface{}{
         .          .    336:           "ChannelID": 0,
         .      100ms    337:           "Channels":  []ChannelInfo{},
         .          .    338:           "User":      nil,
         .          .    339:   })
         .          .    340:}
         .          .    341:
         .          .    342:func postLogin(c echo.Context) error {
ROUTINE ======================== main.queryChannels in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      100ms (flat, cum)  0.24% of Total
         .          .    488:   h := HaveRead{}
         .          .    489:
         .          .    490:   err := db.Get(&h, "SELECT * FROM haveread WHERE user_id = ? AND channel_id = ?",
         .          .    491:           userID, chID)
         .          .    492:
         .      100ms    493:   if err == sql.ErrNoRows {
         .          .    494:           return 0, nil
         .          .    495:   } else if err != nil {
         .          .    496:           return 0, err
         .          .    497:   }
         .          .    498:   return h.MessageID, nil
ROUTINE ======================== main.queryHaveRead in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      5.44s (flat, cum) 12.92% of Total
         .          .    500:
         .          .    501:func fetchUnread(c echo.Context) error {
         .          .    502:   userID := sessUserID(c)
         .          .    503:   if userID == 0 {
         .          .    504:           return c.NoContent(http.StatusForbidden)
         .       10ms    505:   }
         .          .    506:
         .      5.43s    507:   time.Sleep(time.Second)
         .          .    508:
         .          .    509:   channels, err := queryChannels()
         .          .    510:   if err != nil {
         .          .    511:           return err
         .          .    512:   }
ROUTINE ======================== main.randomString in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       10ms (flat, cum) 0.024% of Total
         .          .    230:   return string(b)
         .          .    231:}
         .          .    232:
         .          .    233:func register(name, password string) (int64, error) {
         .          .    234:   salt := randomString(20)
         .       10ms    235:   digest := fmt.Sprintf("%x", sha1.Sum([]byte(salt+password)))
         .          .    236:
         .          .    237:   res, err := db.Exec(
         .          .    238:           "INSERT INTO user (name, salt, password, display_name, avatar_icon, created_at)"+
         .          .    239:                   " VALUES (?, ?, ?, ?, ?, NOW())",
         .          .    240:           name, salt, digest, name, "default.png")
ROUTINE ======================== main.register in /home/isucon/isubata/webapp/go/src/isubata/app.go
      10ms      180ms (flat, cum)  0.43% of Total
         .          .    236:
         .          .    237:   res, err := db.Exec(
         .          .    238:           "INSERT INTO user (name, salt, password, display_name, avatar_icon, created_at)"+
         .          .    239:                   " VALUES (?, ?, ?, ?, ?, NOW())",
         .          .    240:           name, salt, digest, name, "default.png")
         .       10ms    241:   if err != nil {
         .          .    242:           return 0, err
         .          .    243:   }
         .      160ms    244:   return res.LastInsertId()
         .          .    245:}
         .          .    246:
         .          .    247:// request handlers
         .          .    248:
         .          .    249:func getInitialize(c echo.Context) error {
         .          .    250:   db.MustExec("DELETE FROM user WHERE id > 1000")
      10ms       10ms    251:   db.MustExec("DELETE FROM image WHERE id > 1001")
         .          .    252:   db.MustExec("DELETE FROM channel WHERE id > 10")
         .          .    253:   db.MustExec("DELETE FROM message WHERE id > 10000")
         .          .    254:   db.MustExec("DELETE FROM haveread")
         .          .    255:   return c.String(204, "")
         .          .    256:}
ROUTINE ======================== main.sessSetUserID in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      420ms (flat, cum)     1% of Total
         .          .    188:           HttpOnly: true,
         .          .    189:           MaxAge:   360000,
         .          .    190:   }
         .          .    191:   sess.Values["user_id"] = id
         .          .    192:   sess.Save(c.Request(), c.Response())
         .      250ms    193:}
         .          .    194:
         .          .    195:func ensureLogin(c echo.Context) (*User, error) {
         .          .    196:   var user *User
         .          .    197:   var err error
         .          .    198:
         .      170ms    199:   userID := sessUserID(c)
         .          .    200:   if userID == 0 {
         .          .    201:           goto redirect
         .          .    202:   }
         .          .    203:
         .          .    204:   user, err = getUser(userID)
ROUTINE ======================== main.sessUserID in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      770ms (flat, cum)  1.83% of Total
         .          .    179:   if x, ok := sess.Values["user_id"]; ok {
         .          .    180:           userID, _ = x.(int64)
         .          .    181:   }
         .          .    182:   return userID
         .          .    183:}
         .      770ms    184:
         .          .    185:func sessSetUserID(c echo.Context, id int64) {
         .          .    186:   sess, _ := session.Get("session", c)
         .          .    187:   sess.Options = &sessions.Options{
         .          .    188:           HttpOnly: true,
         .          .    189:           MaxAge:   360000,
ROUTINE ======================== net/http.requestBodyRemains in /usr/local/go/src/net/http/server.go
      10ms       10ms (flat, cum) 0.024% of Total
 Error: could not find file src/net/http/server.go on path /home/isucon/isubata/webapp/go
ROUTINE ======================== runtime.main in /usr/local/go/src/runtime/proc.go
         0      550ms (flat, cum)  1.31% of Total
 Error: could not find file src/runtime/proc.go on path /home/isucon/isubata/webapp/go
