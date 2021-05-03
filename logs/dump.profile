(pprof) list main
Total: 4.35s
ROUTINE ======================== main.(*Renderer).Render in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      170ms (flat, cum)  3.91% of Total
         .          .     38:type Renderer struct {
         .          .     39:   templates *template.Template
         .          .     40:}
         .          .     41:
         .          .     42:func (r *Renderer) Render(w io.Writer, name string, data interface{}, c echo.Context) error {
         .      170ms     43:   return r.templates.ExecuteTemplate(w, name, data)
         .          .     44:}
         .          .     45:
         .          .     46:func init() {
         .          .     47:   seedBuf := make([]byte, 8)
         .          .     48:   crand.Read(seedBuf)
ROUTINE ======================== main.addMessage in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       10ms (flat, cum)  0.23% of Total
         .          .    104:   }
         .          .    105:   return &u, nil
         .          .    106:}
         .          .    107:
         .          .    108:func addMessage(channelID, userID int64, content string) (int64, error) {
         .       10ms    109:   res, err := db.Exec(
         .          .    110:           "INSERT INTO message (channel_id, user_id, content, created_at) VALUES (?, ?, ?, NOW())",
         .          .    111:           channelID, userID, content)
         .          .    112:   if err != nil {
         .          .    113:           return 0, err
         .          .    114:   }
ROUTINE ======================== main.ensureLogin in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       80ms (flat, cum)  1.84% of Total
         .          .    151:
         .          .    152:func ensureLogin(c echo.Context) (*User, error) {
         .          .    153:   var user *User
         .          .    154:   var err error
         .          .    155:
         .       40ms    156:   userID := sessUserID(c)
         .          .    157:   if userID == 0 {
         .          .    158:           goto redirect
         .          .    159:   }
         .          .    160:
         .       40ms    161:   user, err = getUser(userID)
         .          .    162:   if err != nil {
         .          .    163:           return nil, err
         .          .    164:   }
         .          .    165:   if user == nil {
         .          .    166:           sess, _ := session.Get("session", c)
ROUTINE ======================== main.fetchUnread in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      320ms (flat, cum)  7.36% of Total
         .          .    436:   }
         .          .    437:   return h.MessageID, nil
         .          .    438:}
         .          .    439:
         .          .    440:func fetchUnread(c echo.Context) error {
         .       10ms    441:   userID := sessUserID(c)
         .          .    442:   if userID == 0 {
         .          .    443:           return c.NoContent(http.StatusForbidden)
         .          .    444:   }
         .          .    445:
         .          .    446:   time.Sleep(time.Second)
         .          .    447:
         .       10ms    448:   channels, err := queryChannels()
         .          .    449:   if err != nil {
         .          .    450:           return err
         .          .    451:   }
         .          .    452:
         .          .    453:   resp := []map[string]interface{}{}
         .          .    454:
         .          .    455:   for _, chID := range channels {
         .      150ms    456:           lastID, err := queryHaveRead(userID, chID)
         .          .    457:           if err != nil {
         .          .    458:                   return err
         .          .    459:           }
         .          .    460:
         .          .    461:           var cnt int64
         .          .    462:           if lastID > 0 {
         .          .    463:                   err = db.Get(&cnt,
         .          .    464:                           "SELECT COUNT(*) as cnt FROM message WHERE channel_id = ? AND ? < id",
         .          .    465:                           chID, lastID)
         .          .    466:           } else {
         .      130ms    467:                   err = db.Get(&cnt,
         .       10ms    468:                           "SELECT COUNT(*) as cnt FROM message WHERE channel_id = ?",
         .          .    469:                           chID)
         .          .    470:           }
         .          .    471:           if err != nil {
         .          .    472:                   return err
         .          .    473:           }
         .          .    474:           r := map[string]interface{}{
         .       10ms    475:                   "channel_id": chID,
         .          .    476:                   "unread":     cnt}
         .          .    477:           resp = append(resp, r)
         .          .    478:   }
         .          .    479:
         .          .    480:   return c.JSON(http.StatusOK, resp)
ROUTINE ======================== main.getChannel in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      180ms (flat, cum)  4.14% of Total
         .          .    230:   UpdatedAt   time.Time `db:"updated_at"`
         .          .    231:   CreatedAt   time.Time `db:"created_at"`
         .          .    232:}
         .          .    233:
         .          .    234:func getChannel(c echo.Context) error {
         .       20ms    235:   user, err := ensureLogin(c)
         .          .    236:   if user == nil {
         .          .    237:           return err
         .          .    238:   }
         .          .    239:   cID, err := strconv.Atoi(c.Param("channel_id"))
         .          .    240:   if err != nil {
         .          .    241:           return err
         .          .    242:   }
         .          .    243:   channels := []ChannelInfo{}
         .       80ms    244:   err = db.Select(&channels, "SELECT * FROM channel ORDER BY id")
         .          .    245:   if err != nil {
         .          .    246:           return err
         .          .    247:   }
         .          .    248:
         .          .    249:   var desc string
         .          .    250:   for _, ch := range channels {
         .          .    251:           if ch.ID == int64(cID) {
         .          .    252:                   desc = ch.Description
         .          .    253:                   break
         .          .    254:           }
         .          .    255:   }
         .       80ms    256:   return c.Render(http.StatusOK, "channel", map[string]interface{}{
         .          .    257:           "ChannelID":   cID,
         .          .    258:           "Channels":    channels,
         .          .    259:           "User":        user,
         .          .    260:           "Description": desc,
         .          .    261:   })
ROUTINE ======================== main.getHistory in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      120ms (flat, cum)  2.76% of Total
         .          .    484:   chID, err := strconv.ParseInt(c.Param("channel_id"), 10, 64)
         .          .    485:   if err != nil || chID <= 0 {
         .          .    486:           return ErrBadReqeust
         .          .    487:   }
         .          .    488:
         .       20ms    489:   user, err := ensureLogin(c)
         .          .    490:   if user == nil {
         .          .    491:           return err
         .          .    492:   }
         .          .    493:
         .          .    494:   var page int64
         .          .    495:   pageStr := c.QueryParam("page")
         .          .    496:   if pageStr == "" {
         .          .    497:           page = 1
         .          .    498:   } else {
         .          .    499:           page, err = strconv.ParseInt(pageStr, 10, 64)
         .          .    500:           if err != nil || page < 1 {
         .          .    501:                   return ErrBadReqeust
         .          .    502:           }
         .          .    503:   }
         .          .    504:
         .          .    505:   const N = 20
         .          .    506:   var cnt int64
         .          .    507:   err = db.Get(&cnt, "SELECT COUNT(*) as cnt FROM message WHERE channel_id = ?", chID)
         .          .    508:   if err != nil {
         .          .    509:           return err
         .          .    510:   }
         .          .    511:   maxPage := int64(cnt+N-1) / N
         .          .    512:   if maxPage == 0 {
         .          .    513:           maxPage = 1
         .          .    514:   }
         .          .    515:   if page > maxPage {
         .          .    516:           return ErrBadReqeust
         .          .    517:   }
         .          .    518:
         .          .    519:   messages := []Message{}
         .       10ms    520:   err = db.Select(&messages,
         .          .    521:           "SELECT * FROM message WHERE channel_id = ? ORDER BY id DESC LIMIT ? OFFSET ?",
         .          .    522:           chID, N, (page-1)*N)
         .          .    523:   if err != nil {
         .          .    524:           return err
         .          .    525:   }
         .          .    526:
         .          .    527:   mjson := make([]map[string]interface{}, 0)
         .          .    528:   for i := len(messages) - 1; i >= 0; i-- {
         .       20ms    529:           r, err := jsonifyMessage(messages[i])
         .          .    530:           if err != nil {
         .          .    531:                   return err
         .          .    532:           }
         .          .    533:           mjson = append(mjson, r)
         .          .    534:   }
         .          .    535:
         .          .    536:   channels := []ChannelInfo{}
         .       30ms    537:   err = db.Select(&channels, "SELECT * FROM channel ORDER BY id")
         .          .    538:   if err != nil {
         .          .    539:           return err
         .          .    540:   }
         .          .    541:
         .       40ms    542:   return c.Render(http.StatusOK, "history", map[string]interface{}{
         .          .    543:           "ChannelID": chID,
         .          .    544:           "Channels":  channels,
         .          .    545:           "Messages":  mjson,
         .          .    546:           "MaxPage":   maxPage,
         .          .    547:           "Page":      page,
ROUTINE ======================== main.getIcon in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      1.40s (flat, cum) 32.18% of Total
         .          .    684:}
         .          .    685:
         .          .    686:func getIcon(c echo.Context) error {
         .          .    687:   var name string
         .          .    688:   var data []byte
         .      100ms    689:   err := db.QueryRow("SELECT name, data FROM image WHERE name = ?",
         .      1.20s    690:           c.Param("file_name")).Scan(&name, &data)
         .          .    691:   if err == sql.ErrNoRows {
         .          .    692:           return echo.ErrNotFound
         .          .    693:   }
         .          .    694:   if err != nil {
         .          .    695:           return err
         .          .    696:   }
         .          .    697:
         .          .    698:   mime := ""
         .          .    699:   switch true {
         .          .    700:   case strings.HasSuffix(name, ".jpg"), strings.HasSuffix(name, ".jpeg"):
         .          .    701:           mime = "image/jpeg"
         .          .    702:   case strings.HasSuffix(name, ".png"):
         .          .    703:           mime = "image/png"
         .          .    704:   case strings.HasSuffix(name, ".gif"):
         .          .    705:           mime = "image/gif"
         .          .    706:   default:
         .          .    707:           return echo.ErrNotFound
         .          .    708:   }
         .      100ms    709:   return c.Blob(http.StatusOK, mime, data)
         .          .    710:}
         .          .    711:
         .          .    712:func tAdd(a, b int64) int64 {
         .          .    713:   return a + b
         .          .    714:}
ROUTINE ======================== main.getMessage in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      430ms (flat, cum)  9.89% of Total
         .          .    366:   r["content"] = m.Content
         .          .    367:   return r, nil
         .          .    368:}
         .          .    369:
         .          .    370:func getMessage(c echo.Context) error {
         .       10ms    371:   userID := sessUserID(c)
         .          .    372:   if userID == 0 {
         .          .    373:           return c.NoContent(http.StatusForbidden)
         .          .    374:   }
         .          .    375:
         .          .    376:   chanID, err := strconv.ParseInt(c.QueryParam("channel_id"), 10, 64)
         .          .    377:   if err != nil {
         .          .    378:           return err
         .          .    379:   }
         .          .    380:   lastID, err := strconv.ParseInt(c.QueryParam("last_message_id"), 10, 64)
         .          .    381:   if err != nil {
         .          .    382:           return err
         .          .    383:   }
         .          .    384:
         .       30ms    385:   messages, err := queryMessages(chanID, lastID)
         .          .    386:   if err != nil {
         .          .    387:           return err
         .          .    388:   }
         .          .    389:
         .          .    390:   response := make([]map[string]interface{}, 0)
         .          .    391:   for i := len(messages) - 1; i >= 0; i-- {
         .          .    392:           m := messages[i]
         .      380ms    393:           r, err := jsonifyMessage(m)
         .          .    394:           if err != nil {
         .          .    395:                   return err
         .          .    396:           }
         .          .    397:           response = append(response, r)
         .          .    398:   }
         .          .    399:
         .          .    400:   if len(messages) > 0 {
         .          .    401:           _, err := db.Exec("INSERT INTO haveread (user_id, channel_id, message_id, updated_at, created_at)"+
         .          .    402:                   " VALUES (?, ?, ?, NOW(), NOW())"+
         .          .    403:                   " ON DUPLICATE KEY UPDATE message_id = ?, updated_at = NOW()",
         .          .    404:                   userID, chanID, messages[0].ID, messages[0].ID)
         .          .    405:           if err != nil {
         .          .    406:                   return err
         .          .    407:           }
         .          .    408:   }
         .          .    409:
         .       10ms    410:   return c.JSON(http.StatusOK, response)
         .          .    411:}
         .          .    412:
         .          .    413:func queryChannels() ([]int64, error) {
         .          .    414:   res := []int64{}
         .          .    415:   err := db.Select(&res, "SELECT id FROM channel")
ROUTINE ======================== main.getProfile in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       60ms (flat, cum)  1.38% of Total
         .          .    554:   if self == nil {
         .          .    555:           return err
         .          .    556:   }
         .          .    557:
         .          .    558:   channels := []ChannelInfo{}
         .       10ms    559:   err = db.Select(&channels, "SELECT * FROM channel ORDER BY id")
         .          .    560:   if err != nil {
         .          .    561:           return err
         .          .    562:   }
         .          .    563:
         .          .    564:   userName := c.Param("user_name")
         .          .    565:   var other User
         .          .    566:   err = db.Get(&other, "SELECT * FROM user WHERE name = ?", userName)
         .          .    567:   if err == sql.ErrNoRows {
         .          .    568:           return echo.ErrNotFound
         .          .    569:   }
         .          .    570:   if err != nil {
         .          .    571:           return err
         .          .    572:   }
         .          .    573:
         .       50ms    574:   return c.Render(http.StatusOK, "profile", map[string]interface{}{
         .          .    575:           "ChannelID":   0,
         .          .    576:           "Channels":    channels,
         .          .    577:           "User":        self,
         .          .    578:           "Other":       other,
         .          .    579:           "SelfProfile": self.ID == other.ID,
ROUTINE ======================== main.getUser in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       40ms (flat, cum)  0.92% of Total
         .          .     94:   CreatedAt   time.Time `json:"-" db:"created_at"`
         .          .     95:}
         .          .     96:
         .          .     97:func getUser(userID int64) (*User, error) {
         .          .     98:   u := User{}
         .       40ms     99:   if err := db.Get(&u, "SELECT * FROM user WHERE id = ?", userID); err != nil {
         .          .    100:           if err == sql.ErrNoRows {
         .          .    101:                   return nil, nil
         .          .    102:           }
         .          .    103:           return nil, err
         .          .    104:   }
ROUTINE ======================== main.jsonifyMessage in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      400ms (flat, cum)  9.20% of Total
         .          .    351:   return c.NoContent(204)
         .          .    352:}
         .          .    353:
         .          .    354:func jsonifyMessage(m Message) (map[string]interface{}, error) {
         .          .    355:   u := User{}
         .      390ms    356:   err := db.Get(&u, "SELECT name, display_name, avatar_icon FROM user WHERE id = ?",
         .          .    357:           m.UserID)
         .          .    358:   if err != nil {
         .          .    359:           return nil, err
         .          .    360:   }
         .          .    361:
         .          .    362:   r := make(map[string]interface{})
         .          .    363:   r["id"] = m.ID
         .          .    364:   r["user"] = u
         .       10ms    365:   r["date"] = m.CreatedAt.Format("2006/01/02 15:04:05")
         .          .    366:   r["content"] = m.Content
         .          .    367:   return r, nil
         .          .    368:}
         .          .    369:
         .          .    370:func getMessage(c echo.Context) error {
ROUTINE ======================== main.main in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       40ms (flat, cum)  0.92% of Total
         .          .    759:
         .          .    760:   e.GET("add_channel", getAddChannel)
         .          .    761:   e.POST("add_channel", postAddChannel)
         .          .    762:   e.GET("/icons/:file_name", getIcon)
         .          .    763:
         .       40ms    764:   e.Start(":5000")
         .          .    765:}
ROUTINE ======================== main.postLogin in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       40ms (flat, cum)  0.92% of Total
         .          .    302:   if name == "" || pw == "" {
         .          .    303:           return ErrBadReqeust
         .          .    304:   }
         .          .    305:
         .          .    306:   var user User
         .       30ms    307:   err := db.Get(&user, "SELECT * FROM user WHERE name = ?", name)
         .          .    308:   if err == sql.ErrNoRows {
         .          .    309:           return echo.ErrForbidden
         .          .    310:   } else if err != nil {
         .          .    311:           return err
         .          .    312:   }
         .          .    313:
         .          .    314:   digest := fmt.Sprintf("%x", sha1.Sum([]byte(user.Salt+pw)))
         .          .    315:   if digest != user.Password {
         .          .    316:           return echo.ErrForbidden
         .          .    317:   }
         .       10ms    318:   sessSetUserID(c, user.ID)
         .          .    319:   return c.Redirect(http.StatusSeeOther, "/")
         .          .    320:}
         .          .    321:
         .          .    322:func getLogout(c echo.Context) error {
         .          .    323:   sess, _ := session.Get("session", c)
ROUTINE ======================== main.postMessage in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       50ms (flat, cum)  1.15% of Total
         .          .    325:   sess.Save(c.Request(), c.Response())
         .          .    326:   return c.Redirect(http.StatusSeeOther, "/")
         .          .    327:}
         .          .    328:
         .          .    329:func postMessage(c echo.Context) error {
         .       40ms    330:   user, err := ensureLogin(c)
         .          .    331:   if user == nil {
         .          .    332:           return err
         .          .    333:   }
         .          .    334:
         .          .    335:   message := c.FormValue("message")
         .          .    336:   if message == "" {
         .          .    337:           return echo.ErrForbidden
         .          .    338:   }
         .          .    339:
         .          .    340:   var chanID int64
         .          .    341:   if x, err := strconv.Atoi(c.FormValue("channel_id")); err != nil {
         .          .    342:           return echo.ErrForbidden
         .          .    343:   } else {
         .          .    344:           chanID = int64(x)
         .          .    345:   }
         .          .    346:
         .       10ms    347:   if _, err := addMessage(chanID, user.ID, message); err != nil {
         .          .    348:           return err
         .          .    349:   }
         .          .    350:
         .          .    351:   return c.NoContent(204)
         .          .    352:}
ROUTINE ======================== main.postProfile in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       90ms (flat, cum)  2.07% of Total
         .          .    629:   }
         .          .    630:
         .          .    631:   avatarName := ""
         .          .    632:   var avatarData []byte
         .          .    633:
         .       60ms    634:   if fh, err := c.FormFile("avatar_icon"); err == http.ErrMissingFile {
         .          .    635:           // no file upload
         .          .    636:   } else if err != nil {
         .          .    637:           return err
         .          .    638:   } else {
         .          .    639:           dotPos := strings.LastIndexByte(fh.Filename, '.')
         .          .    640:           if dotPos < 0 {
         .          .    641:                   return ErrBadReqeust
         .          .    642:           }
         .          .    643:           ext := fh.Filename[dotPos:]
         .          .    644:           switch ext {
         .          .    645:           case ".jpg", ".jpeg", ".png", ".gif":
         .          .    646:                   break
         .          .    647:           default:
         .          .    648:                   return ErrBadReqeust
         .          .    649:           }
         .          .    650:
         .          .    651:           file, err := fh.Open()
         .          .    652:           if err != nil {
         .          .    653:                   return err
         .          .    654:           }
         .          .    655:           avatarData, _ = ioutil.ReadAll(file)
         .          .    656:           file.Close()
         .          .    657:
         .          .    658:           if len(avatarData) > avatarMaxBytes {
         .          .    659:                   return ErrBadReqeust
         .          .    660:           }
         .          .    661:
         .       10ms    662:           avatarName = fmt.Sprintf("%x%s", sha1.Sum(avatarData), ext)
         .          .    663:   }
         .          .    664:
         .          .    665:   if avatarName != "" && len(avatarData) > 0 {
         .       10ms    666:           _, err := db.Exec("INSERT INTO image (name, data) VALUES (?, ?)", avatarName, avatarData)
         .          .    667:           if err != nil {
         .          .    668:                   return err
         .          .    669:           }
         .       10ms    670:           _, err = db.Exec("UPDATE user SET avatar_icon = ? WHERE id = ?", avatarName, self.ID)
         .          .    671:           if err != nil {
         .          .    672:                   return err
         .          .    673:           }
         .          .    674:   }
         .          .    675:
ROUTINE ======================== main.queryChannels in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       10ms (flat, cum)  0.23% of Total
         .          .    410:   return c.JSON(http.StatusOK, response)
         .          .    411:}
         .          .    412:
         .          .    413:func queryChannels() ([]int64, error) {
         .          .    414:   res := []int64{}
         .       10ms    415:   err := db.Select(&res, "SELECT id FROM channel")
         .          .    416:   return res, err
         .          .    417:}
         .          .    418:
         .          .    419:func queryHaveRead(userID, chID int64) (int64, error) {
         .          .    420:   type HaveRead struct {
ROUTINE ======================== main.queryHaveRead in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0      150ms (flat, cum)  3.45% of Total
         .          .    424:           UpdatedAt time.Time `db:"updated_at"`
         .          .    425:           CreatedAt time.Time `db:"created_at"`
         .          .    426:   }
         .          .    427:   h := HaveRead{}
         .          .    428:
         .      150ms    429:   err := db.Get(&h, "SELECT * FROM haveread WHERE user_id = ? AND channel_id = ?",
         .          .    430:           userID, chID)
         .          .    431:
         .          .    432:   if err == sql.ErrNoRows {
         .          .    433:           return 0, nil
         .          .    434:   } else if err != nil {
ROUTINE ======================== main.queryMessages in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       30ms (flat, cum)  0.69% of Total
         .          .    123:   CreatedAt time.Time `db:"created_at"`
         .          .    124:}
         .          .    125:
         .          .    126:func queryMessages(chanID, lastID int64) ([]Message, error) {
         .          .    127:   msgs := []Message{}
         .       30ms    128:   err := db.Select(&msgs, "SELECT * FROM message WHERE id > ? AND channel_id = ? ORDER BY id DESC LIMIT 100",
         .          .    129:           lastID, chanID)
         .          .    130:   return msgs, err
         .          .    131:}
         .          .    132:
         .          .    133:func sessUserID(c echo.Context) int64 {
ROUTINE ======================== main.sessSetUserID in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       10ms (flat, cum)  0.23% of Total
         .          .    138:   }
         .          .    139:   return userID
         .          .    140:}
         .          .    141:
         .          .    142:func sessSetUserID(c echo.Context, id int64) {
         .       10ms    143:   sess, _ := session.Get("session", c)
         .          .    144:   sess.Options = &sessions.Options{
         .          .    145:           HttpOnly: true,
         .          .    146:           MaxAge:   360000,
         .          .    147:   }
         .          .    148:   sess.Values["user_id"] = id
ROUTINE ======================== main.sessUserID in /home/isucon/isubata/webapp/go/src/isubata/app.go
         0       60ms (flat, cum)  1.38% of Total
         .          .    129:           lastID, chanID)
         .          .    130:   return msgs, err
         .          .    131:}
         .          .    132:
         .          .    133:func sessUserID(c echo.Context) int64 {
         .       60ms    134:   sess, _ := session.Get("session", c)
         .          .    135:   var userID int64
         .          .    136:   if x, ok := sess.Values["user_id"]; ok {
         .          .    137:           userID, _ = x.(int64)
         .          .    138:   }
         .          .    139:   return userID
ROUTINE ======================== runtime.main in /usr/local/go/src/runtime/proc.go
         0       40ms (flat, cum)  0.92% of Total
         .          .    190:           // A program compiled with -buildmode=c-archive or c-shared
         .          .    191:           // has a main, but it is not executed.
         .          .    192:           return
         .          .    193:   }
         .          .    194:   fn = main_main // make an indirect call, as the linker doesn't know the address of the main package when laying down the runtime
         .       40ms    195:   fn()
         .          .    196:   if raceenabled {
         .          .    197:           racefini()
         .          .    198:   }
         .          .    199:
         .          .    200:   // Make racy client program work: if panicking on
