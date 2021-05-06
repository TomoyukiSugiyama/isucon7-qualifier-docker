(pprof) list main
Total: 43.01s
ROUTINE ======================== main.(*Renderer).Render in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      2.38s (flat, cum)  5.53% of Total
         .          .     41:type Renderer struct {
         .          .     42:   templates *template.Template
         .          .     43:}
         .          .     44:
         .          .     45:func (r *Renderer) Render(w io.Writer, name string, data interface{}, c echo.Context) error {
         .      2.38s     46:   return r.templates.ExecuteTemplate(w, name, data)
         .          .     47:}
         .          .     48:
         .          .     49:var ctx = context.Background()
         .          .     50:
         .          .     51:var rdb *redis.Client
ROUTINE ======================== main.addMessage in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      160ms (flat, cum)  0.37% of Total
         .          .    154:   }
         .          .    155:   return &u, nil
         .          .    156:}
         .          .    157:
         .          .    158:func addMessage(channelID, userID int64, content string) (int64, error) {
         .      150ms    159:   res, err := db.Exec(
         .       10ms    160:           "INSERT INTO message (channel_id, user_id, content, created_at) VALUES (?, ?, ?, NOW())",
         .          .    161:           channelID, userID, content)
         .          .    162:   if err != nil {
         .          .    163:           return 0, err
         .          .    164:   }
         .          .    165:   return res.LastInsertId()
ROUTINE ======================== main.ensureLogin in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      1.25s (flat, cum)  2.91% of Total
         .          .    201:
         .          .    202:func ensureLogin(c echo.Context) (*User, error) {
         .          .    203:   var user *User
         .          .    204:   var err error
         .          .    205:
         .      540ms    206:   userID := sessUserID(c)
         .          .    207:   if userID == 0 {
         .          .    208:           goto redirect
         .          .    209:   }
         .          .    210:
         .      710ms    211:   user, err = getUser(userID)
         .          .    212:   if err != nil {
         .          .    213:           return nil, err
         .          .    214:   }
         .          .    215:   if user == nil {
         .          .    216:           sess, _ := session.Get("session", c)
ROUTINE ======================== main.fetchUnread in /home/isucon/isubata/webapp/go/src/isubata/app.go
      10ms     10.25s (flat, cum) 23.83% of Total
         .          .    486:   }
         .          .    487:   return h.MessageID, nil
         .          .    488:}
         .          .    489:
         .          .    490:func fetchUnread(c echo.Context) error {
         .       40ms    491:   userID := sessUserID(c)
         .          .    492:   if userID == 0 {
         .          .    493:           return c.NoContent(http.StatusForbidden)
         .          .    494:   }
         .          .    495:
         .          .    496:   time.Sleep(time.Second)
         .          .    497:
         .       70ms    498:   channels, err := queryChannels()
         .          .    499:   if err != nil {
         .          .    500:           return err
         .          .    501:   }
         .          .    502:
         .          .    503:   resp := []map[string]interface{}{}
         .          .    504:
      10ms       10ms    505:   for _, chID := range channels {
         .      5.09s    506:           lastID, err := queryHaveRead(userID, chID)
         .          .    507:           if err != nil {
         .          .    508:                   return err
         .          .    509:           }
         .          .    510:
         .          .    511:           var cnt int64
         .          .    512:           if lastID > 0 {
         .       60ms    513:                   err = db.Get(&cnt,
         .       10ms    514:                           "SELECT COUNT(*) as cnt FROM message WHERE channel_id = ? AND ? < id",
         .          .    515:                           chID, lastID)
         .          .    516:           } else {
         .      4.90s    517:                   err = db.Get(&cnt,
         .          .    518:                           "SELECT COUNT(*) as cnt FROM message WHERE channel_id = ?",
         .          .    519:                           chID)
         .          .    520:           }
         .          .    521:           if err != nil {
         .          .    522:                   return err
         .          .    523:           }
         .       20ms    524:           r := map[string]interface{}{
         .          .    525:                   "channel_id": chID,
         .          .    526:                   "unread":     cnt}
         .          .    527:           resp = append(resp, r)
         .          .    528:   }
         .          .    529:
         .       50ms    530:   return c.JSON(http.StatusOK, resp)
         .          .    531:}
         .          .    532:
         .          .    533:func getHistory(c echo.Context) error {
         .          .    534:   chID, err := strconv.ParseInt(c.Param("channel_id"), 10, 64)
         .          .    535:   if err != nil || chID <= 0 {
ROUTINE ======================== main.getChannel in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      940ms (flat, cum)  2.19% of Total
         .          .    280:   UpdatedAt   time.Time `db:"updated_at"`
         .          .    281:   CreatedAt   time.Time `db:"created_at"`
         .          .    282:}
         .          .    283:
         .          .    284:func getChannel(c echo.Context) error {
         .      160ms    285:   user, err := ensureLogin(c)
         .          .    286:   if user == nil {
         .          .    287:           return err
         .          .    288:   }
         .          .    289:   cID, err := strconv.Atoi(c.Param("channel_id"))
         .          .    290:   if err != nil {
         .          .    291:           return err
         .          .    292:   }
         .          .    293:   channels := []ChannelInfo{}
         .      140ms    294:   err = db.Select(&channels, "SELECT * FROM channel ORDER BY id")
         .          .    295:   if err != nil {
         .          .    296:           return err
         .          .    297:   }
         .          .    298:
         .          .    299:   var desc string
         .          .    300:   for _, ch := range channels {
         .          .    301:           if ch.ID == int64(cID) {
         .          .    302:                   desc = ch.Description
         .          .    303:                   break
         .          .    304:           }
         .          .    305:   }
         .      630ms    306:   return c.Render(http.StatusOK, "channel", map[string]interface{}{
         .          .    307:           "ChannelID":   cID,
         .          .    308:           "Channels":    channels,
         .          .    309:           "User":        user,
         .       10ms    310:           "Description": desc,
         .          .    311:   })
         .          .    312:}
         .          .    313:
         .          .    314:func getRegister(c echo.Context) error {
         .          .    315:   return c.Render(http.StatusOK, "register", map[string]interface{}{
ROUTINE ======================== main.getHistory in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      3.52s (flat, cum)  8.18% of Total
         .          .    534:   chID, err := strconv.ParseInt(c.Param("channel_id"), 10, 64)
         .          .    535:   if err != nil || chID <= 0 {
         .          .    536:           return ErrBadReqeust
         .          .    537:   }
         .          .    538:
         .      380ms    539:   user, err := ensureLogin(c)
         .          .    540:   if user == nil {
         .          .    541:           return err
         .          .    542:   }
         .          .    543:
         .          .    544:   var page int64
         .       10ms    545:   pageStr := c.QueryParam("page")
         .          .    546:   if pageStr == "" {
         .          .    547:           page = 1
         .          .    548:   } else {
         .          .    549:           page, err = strconv.ParseInt(pageStr, 10, 64)
         .          .    550:           if err != nil || page < 1 {
         .          .    551:                   return ErrBadReqeust
         .          .    552:           }
         .          .    553:   }
         .          .    554:
         .          .    555:   const N = 20
         .          .    556:   var cnt int64
         .      240ms    557:   err = db.Get(&cnt, "SELECT COUNT(*) as cnt FROM message WHERE channel_id = ?", chID)
         .          .    558:   if err != nil {
         .          .    559:           return err
         .          .    560:   }
         .          .    561:   maxPage := int64(cnt+N-1) / N
         .          .    562:   if maxPage == 0 {
         .          .    563:           maxPage = 1
         .          .    564:   }
         .          .    565:   if page > maxPage {
         .          .    566:           return ErrBadReqeust
         .          .    567:   }
         .          .    568:
         .          .    569:   messages := []Message{}
         .      170ms    570:   err = db.Select(&messages,
         .          .    571:           "SELECT * FROM message WHERE channel_id = ? ORDER BY id DESC LIMIT ? OFFSET ?",
         .          .    572:           chID, N, (page-1)*N)
         .          .    573:   if err != nil {
         .          .    574:           return err
         .          .    575:   }
         .          .    576:
         .          .    577:   mjson := make([]map[string]interface{}, 0)
         .          .    578:   for i := len(messages) - 1; i >= 0; i-- {
         .      1.07s    579:           r, err := jsonifyMessage(messages[i])
         .          .    580:           if err != nil {
         .          .    581:                   return err
         .          .    582:           }
         .          .    583:           mjson = append(mjson, r)
         .          .    584:   }
         .          .    585:
         .          .    586:   channels := []ChannelInfo{}
         .      280ms    587:   err = db.Select(&channels, "SELECT * FROM channel ORDER BY id")
         .          .    588:   if err != nil {
         .          .    589:           return err
         .          .    590:   }
         .          .    591:
         .      1.37s    592:   return c.Render(http.StatusOK, "history", map[string]interface{}{
         .          .    593:           "ChannelID": chID,
         .          .    594:           "Channels":  channels,
         .          .    595:           "Messages":  mjson,
         .          .    596:           "MaxPage":   maxPage,
         .          .    597:           "Page":      page,
ROUTINE ======================== main.getIcon in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      1.04s (flat, cum)  2.42% of Total
         .          .    734:}
         .          .    735:
         .          .    736:func getIcon(c echo.Context) error {
         .          .    737:
         .          .    738:   name := c.Param("file_name")
         .      1.03s    739:   data, err := getKey(name, ctx)
         .          .    740:
         .          .    741:   if err != nil {
         .          .    742:           return err
         .          .    743:   }
         .          .    744:
         .          .    745:   mime := ""
         .          .    746:   switch true {
         .          .    747:   case strings.HasSuffix(name, ".jpg"), strings.HasSuffix(name, ".jpeg"):
         .          .    748:           mime = "image/jpeg"
         .          .    749:   case strings.HasSuffix(name, ".png"):
         .          .    750:           mime = "image/png"
         .          .    751:   case strings.HasSuffix(name, ".gif"):
         .          .    752:           mime = "image/gif"
         .          .    753:   default:
         .          .    754:           return echo.ErrNotFound
         .          .    755:   }
         .          .    756:   return c.Blob(http.StatusOK, mime, data)
         .          .    757:}
         .          .    758:
         .          .    759:func tAdd(a, b int64) int64 {
         .          .    760:   return a + b
         .       10ms    761:}
         .          .    762:
         .          .    763:func tRange(a, b int64) []int64 {
         .          .    764:   r := make([]int64, b-a+1)
         .          .    765:   for i := int64(0); i <= (b - a); i++ {
         .          .    766:           r[i] = a + i
ROUTINE ======================== main.getKey in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      1.03s (flat, cum)  2.39% of Total
         .          .    118:   log.Printf("Save %d images", len(imgs))
         .          .    119:   return nil
         .          .    120:}
         .          .    121:
         .          .    122:func getKey(key string, ctx context.Context) ([]byte, error) {
         .      1.03s    123:   res, err := rdb.Get(ctx, key).Bytes()
         .          .    124:   if err != nil {
         .          .    125:           return nil, err
         .          .    126:   }
         .          .    127:   return res, nil
         .          .    128:}
ROUTINE ======================== main.getLogout in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      100ms (flat, cum)  0.23% of Total
         .          .    368:   sessSetUserID(c, user.ID)
         .          .    369:   return c.Redirect(http.StatusSeeOther, "/")
         .          .    370:}
         .          .    371:
         .          .    372:func getLogout(c echo.Context) error {
         .       80ms    373:   sess, _ := session.Get("session", c)
         .          .    374:   delete(sess.Values, "user_id")
         .       20ms    375:   sess.Save(c.Request(), c.Response())
         .          .    376:   return c.Redirect(http.StatusSeeOther, "/")
         .          .    377:}
         .          .    378:
         .          .    379:func postMessage(c echo.Context) error {
         .          .    380:   user, err := ensureLogin(c)
ROUTINE ======================== main.getMessage in /home/isucon/isubata/webapp/go/src/isubata/app.go
      10ms      5.77s (flat, cum) 13.42% of Total
         .          .    416:   r["content"] = m.Content
         .          .    417:   return r, nil
         .          .    418:}
         .          .    419:
         .          .    420:func getMessage(c echo.Context) error {
         .      160ms    421:   userID := sessUserID(c)
         .          .    422:   if userID == 0 {
         .          .    423:           return c.NoContent(http.StatusForbidden)
         .          .    424:   }
         .          .    425:
         .       10ms    426:   chanID, err := strconv.ParseInt(c.QueryParam("channel_id"), 10, 64)
         .          .    427:   if err != nil {
         .          .    428:           return err
         .          .    429:   }
         .          .    430:   lastID, err := strconv.ParseInt(c.QueryParam("last_message_id"), 10, 64)
         .          .    431:   if err != nil {
         .          .    432:           return err
         .          .    433:   }
         .          .    434:
         .      250ms    435:   messages, err := queryMessages(chanID, lastID)
         .          .    436:   if err != nil {
         .          .    437:           return err
         .          .    438:   }
         .          .    439:
         .          .    440:   response := make([]map[string]interface{}, 0)
         .          .    441:   for i := len(messages) - 1; i >= 0; i-- {
         .          .    442:           m := messages[i]
         .      5.10s    443:           r, err := jsonifyMessage(m)
         .          .    444:           if err != nil {
         .          .    445:                   return err
         .          .    446:           }
      10ms       10ms    447:           response = append(response, r)
         .          .    448:   }
         .          .    449:
         .          .    450:   if len(messages) > 0 {
         .       50ms    451:           _, err := db.Exec("INSERT INTO haveread (user_id, channel_id, message_id, updated_at, created_at)"+
         .          .    452:                   " VALUES (?, ?, ?, NOW(), NOW())"+
         .          .    453:                   " ON DUPLICATE KEY UPDATE message_id = ?, updated_at = NOW()",
         .          .    454:                   userID, chanID, messages[0].ID, messages[0].ID)
         .          .    455:           if err != nil {
         .          .    456:                   return err
         .          .    457:           }
         .          .    458:   }
         .          .    459:
         .      190ms    460:   return c.JSON(http.StatusOK, response)
         .          .    461:}
         .          .    462:
         .          .    463:func queryChannels() ([]int64, error) {
         .          .    464:   res := []int64{}
         .          .    465:   err := db.Select(&res, "SELECT id FROM channel")
ROUTINE ======================== main.getProfile in /home/isucon/isubata/webapp/go/src/isubata/app.go
      10ms      870ms (flat, cum)  2.02% of Total
         .          .    598:           "User":      user,
         .          .    599:   })
         .          .    600:}
         .          .    601:
         .          .    602:func getProfile(c echo.Context) error {
         .      120ms    603:   self, err := ensureLogin(c)
         .          .    604:   if self == nil {
         .          .    605:           return err
         .          .    606:   }
         .          .    607:
         .          .    608:   channels := []ChannelInfo{}
         .      120ms    609:   err = db.Select(&channels, "SELECT * FROM channel ORDER BY id")
         .          .    610:   if err != nil {
         .          .    611:           return err
         .          .    612:   }
         .          .    613:
         .          .    614:   userName := c.Param("user_name")
         .          .    615:   var other User
         .       40ms    616:   err = db.Get(&other, "SELECT * FROM user WHERE name = ?", userName)
         .          .    617:   if err == sql.ErrNoRows {
         .          .    618:           return echo.ErrNotFound
         .          .    619:   }
         .          .    620:   if err != nil {
         .          .    621:           return err
         .          .    622:   }
         .          .    623:
         .      580ms    624:   return c.Render(http.StatusOK, "profile", map[string]interface{}{
         .          .    625:           "ChannelID":   0,
      10ms       10ms    626:           "Channels":    channels,
         .          .    627:           "User":        self,
         .          .    628:           "Other":       other,
         .          .    629:           "SelfProfile": self.ID == other.ID,
         .          .    630:   })
         .          .    631:}
ROUTINE ======================== main.getUser in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      710ms (flat, cum)  1.65% of Total
         .          .    144:   CreatedAt   time.Time `json:"-" db:"created_at"`
         .          .    145:}
         .          .    146:
         .          .    147:func getUser(userID int64) (*User, error) {
         .          .    148:   u := User{}
         .      710ms    149:   if err := db.Get(&u, "SELECT * FROM user WHERE id = ?", userID); err != nil {
         .          .    150:           if err == sql.ErrNoRows {
         .          .    151:                   return nil, nil
         .          .    152:           }
         .          .    153:           return nil, err
         .          .    154:   }
ROUTINE ======================== main.jsonifyMessage in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      6.17s (flat, cum) 14.35% of Total
         .          .    401:   return c.NoContent(204)
         .          .    402:}
         .          .    403:
         .          .    404:func jsonifyMessage(m Message) (map[string]interface{}, error) {
         .          .    405:   u := User{}
         .      5.95s    406:   err := db.Get(&u, "SELECT name, display_name, avatar_icon FROM user WHERE id = ?",
         .          .    407:           m.UserID)
         .          .    408:   if err != nil {
         .          .    409:           return nil, err
         .          .    410:   }
         .          .    411:
         .       20ms    412:   r := make(map[string]interface{})
         .       80ms    413:   r["id"] = m.ID
         .       20ms    414:   r["user"] = u
         .       80ms    415:   r["date"] = m.CreatedAt.Format("2006/01/02 15:04:05")
         .       20ms    416:   r["content"] = m.Content
         .          .    417:   return r, nil
         .          .    418:}
         .          .    419:
         .          .    420:func getMessage(c echo.Context) error {
         .          .    421:   userID := sessUserID(c)
ROUTINE ======================== main.main in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      750ms (flat, cum)  1.74% of Total
         .          .    812:   e.Start(":5000")
         .          .    813:}
ROUTINE ======================== main.postAddChannel in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       50ms (flat, cum)  0.12% of Total
         .          .    648:           "User":      self,
         .          .    649:   })
         .          .    650:}
         .          .    651:
         .          .    652:func postAddChannel(c echo.Context) error {
         .       30ms    653:   self, err := ensureLogin(c)
         .          .    654:   if self == nil {
         .          .    655:           return err
         .          .    656:   }
         .          .    657:
         .          .    658:   name := c.FormValue("name")
         .          .    659:   desc := c.FormValue("description")
         .          .    660:   if name == "" || desc == "" {
         .          .    661:           return ErrBadReqeust
         .          .    662:   }
         .          .    663:
         .       20ms    664:   res, err := db.Exec(
         .          .    665:           "INSERT INTO channel (name, description, updated_at, created_at) VALUES (?, ?, NOW(), NOW())",
         .          .    666:           name, desc)
         .          .    667:   if err != nil {
         .          .    668:           return err
         .          .    669:   }
ROUTINE ======================== main.postLogin in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      920ms (flat, cum)  2.14% of Total
         .          .    345:           "User":      nil,
         .          .    346:   })
         .          .    347:}
         .          .    348:
         .          .    349:func postLogin(c echo.Context) error {
         .       70ms    350:   name := c.FormValue("name")
         .          .    351:   pw := c.FormValue("password")
         .          .    352:   if name == "" || pw == "" {
         .          .    353:           return ErrBadReqeust
         .          .    354:   }
         .          .    355:
         .          .    356:   var user User
         .      450ms    357:   err := db.Get(&user, "SELECT * FROM user WHERE name = ?", name)
         .          .    358:   if err == sql.ErrNoRows {
         .          .    359:           return echo.ErrForbidden
         .          .    360:   } else if err != nil {
         .          .    361:           return err
         .          .    362:   }
         .          .    363:
         .       30ms    364:   digest := fmt.Sprintf("%x", sha1.Sum([]byte(user.Salt+pw)))
         .          .    365:   if digest != user.Password {
         .          .    366:           return echo.ErrForbidden
         .          .    367:   }
         .      370ms    368:   sessSetUserID(c, user.ID)
         .          .    369:   return c.Redirect(http.StatusSeeOther, "/")
         .          .    370:}
         .          .    371:
         .          .    372:func getLogout(c echo.Context) error {
         .          .    373:   sess, _ := session.Get("session", c)
ROUTINE ======================== main.postMessage in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      610ms (flat, cum)  1.42% of Total
         .          .    375:   sess.Save(c.Request(), c.Response())
         .          .    376:   return c.Redirect(http.StatusSeeOther, "/")
         .          .    377:}
         .          .    378:
         .          .    379:func postMessage(c echo.Context) error {
         .      380ms    380:   user, err := ensureLogin(c)
         .          .    381:   if user == nil {
         .          .    382:           return err
         .          .    383:   }
         .          .    384:
         .       60ms    385:   message := c.FormValue("message")
         .          .    386:   if message == "" {
         .          .    387:           return echo.ErrForbidden
         .          .    388:   }
         .          .    389:
         .          .    390:   var chanID int64
         .          .    391:   if x, err := strconv.Atoi(c.FormValue("channel_id")); err != nil {
         .          .    392:           return echo.ErrForbidden
         .          .    393:   } else {
         .          .    394:           chanID = int64(x)
         .          .    395:   }
         .          .    396:
         .      160ms    397:   if _, err := addMessage(chanID, user.ID, message); err != nil {
         .          .    398:           return err
         .          .    399:   }
         .          .    400:
         .       10ms    401:   return c.NoContent(204)
         .          .    402:}
         .          .    403:
         .          .    404:func jsonifyMessage(m Message) (map[string]interface{}, error) {
         .          .    405:   u := User{}
         .          .    406:   err := db.Get(&u, "SELECT name, display_name, avatar_icon FROM user WHERE id = ?",
ROUTINE ======================== main.postProfile in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      1.62s (flat, cum)  3.77% of Total
         .          .    671:   return c.Redirect(http.StatusSeeOther,
         .          .    672:           fmt.Sprintf("/channel/%v", lastID))
         .          .    673:}
         .          .    674:
         .          .    675:func postProfile(c echo.Context) error {
         .      180ms    676:   self, err := ensureLogin(c)
         .          .    677:   if self == nil {
         .          .    678:           return err
         .          .    679:   }
         .          .    680:
         .          .    681:   avatarName := ""
         .          .    682:   var avatarData []byte
         .          .    683:
         .      490ms    684:   if fh, err := c.FormFile("avatar_icon"); err == http.ErrMissingFile {
         .          .    685:           // no file upload
         .          .    686:   } else if err != nil {
         .          .    687:           return err
         .          .    688:   } else {
         .          .    689:           dotPos := strings.LastIndexByte(fh.Filename, '.')
         .          .    690:           if dotPos < 0 {
         .          .    691:                   return ErrBadReqeust
         .          .    692:           }
         .          .    693:           ext := fh.Filename[dotPos:]
         .          .    694:           switch ext {
         .          .    695:           case ".jpg", ".jpeg", ".png", ".gif":
         .          .    696:                   break
         .          .    697:           default:
         .          .    698:                   return ErrBadReqeust
         .          .    699:           }
         .          .    700:
         .          .    701:           file, err := fh.Open()
         .          .    702:           if err != nil {
         .          .    703:                   return err
         .          .    704:           }
         .      270ms    705:           avatarData, _ = ioutil.ReadAll(file)
         .          .    706:           file.Close()
         .          .    707:
         .          .    708:           if len(avatarData) > avatarMaxBytes {
         .          .    709:                   return ErrBadReqeust
         .          .    710:           }
         .          .    711:
         .      220ms    712:           avatarName = fmt.Sprintf("%x%s", sha1.Sum(avatarData), ext)
         .          .    713:   }
         .          .    714:
         .          .    715:   if avatarName != "" && len(avatarData) > 0 {
         .      290ms    716:           _, err := db.Exec("INSERT INTO image (name, data) VALUES (?, ?)", avatarName, avatarData)
         .          .    717:           if err != nil {
         .          .    718:                   return err
         .          .    719:           }
         .       50ms    720:           _, err = db.Exec("UPDATE user SET avatar_icon = ? WHERE id = ?", avatarName, self.ID)
         .          .    721:           if err != nil {
         .          .    722:                   return err
         .          .    723:           }
         .          .    724:   }
         .          .    725:
         .          .    726:   if name := c.FormValue("display_name"); name != "" {
         .      120ms    727:           _, err := db.Exec("UPDATE user SET display_name = ? WHERE id = ?", name, self.ID)
         .          .    728:           if err != nil {
         .          .    729:                   return err
         .          .    730:           }
         .          .    731:   }
         .          .    732:
ROUTINE ======================== main.postRegister in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      160ms (flat, cum)  0.37% of Total
         .          .    318:           "User":      nil,
         .          .    319:   })
         .          .    320:}
         .          .    321:
         .          .    322:func postRegister(c echo.Context) error {
         .       20ms    323:   name := c.FormValue("name")
         .          .    324:   pw := c.FormValue("password")
         .          .    325:   if name == "" || pw == "" {
         .          .    326:           return ErrBadReqeust
         .          .    327:   }
         .      110ms    328:   userID, err := register(name, pw)
         .          .    329:   if err != nil {
         .          .    330:           if merr, ok := err.(*mysql.MySQLError); ok {
         .          .    331:                   if merr.Number == 1062 { // Duplicate entry xxxx for key zzzz
         .          .    332:                           return c.NoContent(http.StatusConflict)
         .          .    333:                   }
         .          .    334:           }
         .          .    335:           return err
         .          .    336:   }
         .       20ms    337:   sessSetUserID(c, userID)
         .       10ms    338:   return c.Redirect(http.StatusSeeOther, "/")
         .          .    339:}
         .          .    340:
         .          .    341:func getLogin(c echo.Context) error {
         .          .    342:   return c.Render(http.StatusOK, "login", map[string]interface{}{
         .          .    343:           "ChannelID": 0,
ROUTINE ======================== main.queryChannels in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       70ms (flat, cum)  0.16% of Total
         .          .    460:   return c.JSON(http.StatusOK, response)
         .          .    461:}
         .          .    462:
         .          .    463:func queryChannels() ([]int64, error) {
         .          .    464:   res := []int64{}
         .       70ms    465:   err := db.Select(&res, "SELECT id FROM channel")
         .          .    466:   return res, err
         .          .    467:}
         .          .    468:
         .          .    469:func queryHaveRead(userID, chID int64) (int64, error) {
         .          .    470:   type HaveRead struct {
ROUTINE ======================== main.queryHaveRead in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      5.09s (flat, cum) 11.83% of Total
         .          .    474:           UpdatedAt time.Time `db:"updated_at"`
         .          .    475:           CreatedAt time.Time `db:"created_at"`
         .          .    476:   }
         .          .    477:   h := HaveRead{}
         .          .    478:
         .      5.09s    479:   err := db.Get(&h, "SELECT * FROM haveread WHERE user_id = ? AND channel_id = ?",
         .          .    480:           userID, chID)
         .          .    481:
         .          .    482:   if err == sql.ErrNoRows {
         .          .    483:           return 0, nil
         .          .    484:   } else if err != nil {
ROUTINE ======================== main.queryMessages in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      250ms (flat, cum)  0.58% of Total
         .          .    173:   CreatedAt time.Time `db:"created_at"`
         .          .    174:}
         .          .    175:
         .          .    176:func queryMessages(chanID, lastID int64) ([]Message, error) {
         .          .    177:   msgs := []Message{}
         .      250ms    178:   err := db.Select(&msgs, "SELECT * FROM message WHERE id > ? AND channel_id = ? ORDER BY id DESC LIMIT 100",
         .          .    179:           lastID, chanID)
         .          .    180:   return msgs, err
         .          .    181:}
         .          .    182:
         .          .    183:func sessUserID(c echo.Context) int64 {
ROUTINE ======================== main.randomString in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       10ms (flat, cum) 0.023% of Total
         .          .    230:func randomString(n int) string {
         .          .    231:   b := make([]byte, n)
         .          .    232:   z := len(LettersAndDigits)
         .          .    233:
         .          .    234:   for i := 0; i < n; i++ {
         .       10ms    235:           b[i] = LettersAndDigits[rand.Intn(z)]
         .          .    236:   }
         .          .    237:   return string(b)
         .          .    238:}
         .          .    239:
         .          .    240:func register(name, password string) (int64, error) {
ROUTINE ======================== main.register in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      110ms (flat, cum)  0.26% of Total
         .          .    236:   }
         .          .    237:   return string(b)
         .          .    238:}
         .          .    239:
         .          .    240:func register(name, password string) (int64, error) {
         .       10ms    241:   salt := randomString(20)
         .          .    242:   digest := fmt.Sprintf("%x", sha1.Sum([]byte(salt+password)))
         .          .    243:
         .      100ms    244:   res, err := db.Exec(
         .          .    245:           "INSERT INTO user (name, salt, password, display_name, avatar_icon, created_at)"+
         .          .    246:                   " VALUES (?, ?, ?, ?, ?, NOW())",
         .          .    247:           name, salt, digest, name, "default.png")
         .          .    248:   if err != nil {
         .          .    249:           return 0, err
ROUTINE ======================== main.sessSetUserID in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      390ms (flat, cum)  0.91% of Total
         .          .    188:   }
         .          .    189:   return userID
         .          .    190:}
         .          .    191:
         .          .    192:func sessSetUserID(c echo.Context, id int64) {
         .      230ms    193:   sess, _ := session.Get("session", c)
         .          .    194:   sess.Options = &sessions.Options{
         .          .    195:           HttpOnly: true,
         .          .    196:           MaxAge:   360000,
         .          .    197:   }
         .          .    198:   sess.Values["user_id"] = id
         .      160ms    199:   sess.Save(c.Request(), c.Response())
         .          .    200:}
         .          .    201:
         .          .    202:func ensureLogin(c echo.Context) (*User, error) {
         .          .    203:   var user *User
         .          .    204:   var err error
ROUTINE ======================== main.sessUserID in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      740ms (flat, cum)  1.72% of Total
         .          .    179:           lastID, chanID)
         .          .    180:   return msgs, err
         .          .    181:}
         .          .    182:
         .          .    183:func sessUserID(c echo.Context) int64 {
         .      740ms    184:   sess, _ := session.Get("session", c)
         .          .    185:   var userID int64
         .          .    186:   if x, ok := sess.Values["user_id"]; ok {
         .          .    187:           userID, _ = x.(int64)
         .          .    188:   }
         .          .    189:   return userID
ROUTINE ======================== net.absDomainName in /usr/local/go/src/net/dnsclient.go
         0       10ms (flat, cum) 0.023% of Total
 Error: could not find file src/net/dnsclient.go on path /home/isucon/isubata/webapp/go
ROUTINE ======================== net/http.requestBodyRemains in /usr/local/go/src/net/http/server.go
      10ms       10ms (flat, cum) 0.023% of Total
 Error: could not find file src/net/http/server.go on path /home/isucon/isubata/webapp/go
ROUTINE ======================== runtime.main in /usr/local/go/src/runtime/proc.go
         0      750ms (flat, cum)  1.74% of Total
 Error: could not find file src/runtime/proc.go on path /home/isucon/isubata/webapp/go
