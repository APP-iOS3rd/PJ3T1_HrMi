// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const {logger} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const fieldValue = admin.firestore.FieldValue;
const timestamp = admin.firestore.Timestamp;

exports.helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase!");
});

const usersString = "users"; // users collection name
const postsString = "posts"; // posts collection name
const drinksString = "drinks"; // drinks collection name
const taggedPostsString = "taggedPosts"; // taggedPosts collection name
const likedUsersIDString = "likedUsersID"; // likedUSersID collection name
const likedPostsString = "likedPosts"; // likedPosts collection name
const likedDrinksString = "likedDrinks"; // likedDrinks collection name
const notificationsString = "notifications"; // notifications collection name

// fcm 보내드립니다..
exports.sendNotification = functions.firestore
  .document("users/{userId}/notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const userId = context.params.userId; // 좋아요 눌러진 post의 userId
    const userRef = db.collection(usersString).doc(userId);
    const userSnapshot = await userRef.get();
    const userFieldData = userSnapshot.data();

    if (userFieldData.notificationAllowed) { // 사용자의 알림설정이 true일 경우
      const userFcmToken = userFieldData.fcmToken; // 사용자의 fcmToken

      const notification = snapshot.data(); // notification data
      const likedUserName = notification.likedUser.userName; // 좋아요 누른 사용자의 이름

      // 알림 메시지 생성
      const message = {
        notification: {
          title: "주다",
          body: `${likedUserName}님이 술상에 좋아요를 눌렀어요.`,
        },
        token: userFcmToken,
      };

      // 알림 전송
      return admin.messaging().send(message)
        .then((response) => {
          console.log("Successfully sent message:", response);
        })
        .catch((error) => {
          console.log("Error sending message:", error);
        });
    } else {
      console.log(`user(userId: ${userId})'s notificationAllowed is false`);
    }
  });

// post 업로드
// root collection인 posts에 post가 업로드됐을 때
exports.onPostCreate = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snapshot, context) =>{
    const postId = context.params.postId; // new post id 추출
    const postFieldData = snapshot.data(); // new post document field data

    const drinkTags = postFieldData.drinkTags;

    // drinkTags collection 순회하여 각 drinkTag document에 post 업로드
    drinkTags.forEach(async (drinkTag) => {
      const drinkId = drinkTag.drinkID; // drink id 추출
      await uploadPostIdToTaggedPost(drinkId, postId, postFieldData);
    });

    // post 작성한 user 및 user id 추출
    const user = postFieldData.user;
    const userId = user.userID;

    // users collection에 post upload
    await uploadPostToUsers(userId, postId, postFieldData);
  });

// drinks 컬렉션의 taggedPosts 하위 컬렉션에 포스트 필드 데이터 업로드
async function uploadPostIdToTaggedPost(drinkId, postId, postFieldData) {
  const drinkRef = db.collection(drinksString).doc(drinkId); // get drink document reference

  if ((await drinkRef.get()).exists) { // drink에 대한 document가 존재 O
    const taggedPostRef = drinkRef.collection(taggedPostsString).doc(postId); // drink document의 하위 taggedPosts collection의 document reference get
    try {
      await taggedPostRef.set(postFieldData); // drink document의 하위 taggedPosts collection의 document에 postFieldData를 업로드
      console.log(`success upload post :: uploadPostIdToTaggedPost(), drinkId: ${drinkId}, postId: ${postId}`);
    } catch (error) {
      console.error(`error :: uploadPostIdToTaggedPost(), drinkId: ${drinkId}, postId: ${postId}`, error);
    }
  } else { // drink에 대한 document가 존재 X
    console.log(`drink document not exist for drinkId: ${drinkId}`);
  }
}

// users 컬렉션의 posts 하위 컬렉션에 포스트 필드 업로드
async function uploadPostToUsers(userId, postId, postFieldData) {
  const userRef = db.collection(usersString).doc(userId); // get user document reference
  const postRef = userRef.collection(postsString).doc(postId); // uset의 하위 posts collection의 document reference get

  try {
    await postRef.set(postFieldData); // user document 하위 posts collection의 document에 postFieldData 업로드
    console.log(`success upload post :: uploadPostToUsers(), userId: ${userId}, postId: ${postId}`);
  } catch (error) {
    console.error(`error :: uploadPostToUsers(), userId: ${userId}, postId: ${postId}`, error);
  }
}

// post 업데이트
// root collection인 posts에 post가 업데이트됐을 때
exports.onPostUpdate = functions.firestore
  .document("posts/{postId}")
  .onUpdate(async (snapshot, context) => {
    // 업데이트 된 post의 id와 field data 추출
    const postId = context.params.postId;
    const postFieldData = snapshot.after.data();

    // post 작성한 user 및 user id 추출
    const userId = postFieldData.user.userID;

    // # 사용자의 'posts' 컬렉션 내 해당 포스트 업데이트
    await updateUserPost(userId, postId, postFieldData);
    // # 사용자의 'likedPosts' 컬렉션 내 해당 포스트 업데이트
    await updateUserLikedPosts(userId, postId, postFieldData);
    // # 사용자의 notification 중 'likedPosts' 컬렉션 내 해당 포스트 업데이트
    await updateNotificationLikedPosts(userId, postId, postFieldData);
    // # 'drinks' 컬렉션 내 'taggedPosts'에서 해당 포스트 업데이트
    await updateTaggedPostDrinks(postId, postFieldData);
  });

// # 사용자의 'posts' 컬렉션 내 해당 포스트 업데이트
async function updateUserPost(userId, postId, postFieldData) {
  const userRef = db.collection(usersString).doc(userId); // get user document reference
  const userPostRef = userRef.collection(postsString).doc(postId); // uset의 하위 posts collection의 document reference get

  if ((await userPostRef.get()).exists) { // user의 하위 posts collection에 해당 post 존재 O
    try {
      await userPostRef.update(postFieldData); // user document 하위 posts collection의 document에 postFieldData 업데이트
      console.log(`success update post :: updateUserPost(), userId: ${userId}, postId: ${postId}`);
    } catch (error) {
     console.error(`error :: updateUserPost(), userId: ${userId}, postId: ${postId}`, error);
    }
  } else { // user의 하위 collection에 해당 post 존재 X
    console.log(`user(userId: ${userId})'s sub collection(posts) not exist post(postId: ${postId})`);
  }
}

// # 사용자의 'likedPosts' 컬렉션 내 해당 포스트 업데이트
async function updateUserLikedPosts(userId, postId, postFieldData) {
  const userRef = db.collection(usersString).doc(userId); // get user document reference
  const userLikedPostRef = userRef.collection(likedPostsString).doc(postId); // uset의 하위 likedPosts collection의 document reference get

  if ((await userLikedPostRef.get()).exists) { // user의 하위 likedPosts collection에 해당 post 존재 O
    try {
      await userLikedPostRef.update(postFieldData); // user document 하위 likedPosts collection document에 postFieldData 업데이트
      console.log(`success update post :: updateUserLikedPosts(), userId: ${userId}, postId: ${postId}`);
    } catch (error) {
      console.error(`error :: updateUserLikedPosts(), userId: ${userId}, postId: ${postId}`, error);
    }
  } else { // user의 하위 likedPosts collection에 해당 post 존재 X
    console.log(`user(userId: ${userId})'s sub collection(likedPosts) not exist post(postId: ${postId})`);
  }
}

// # 사용자의 notification 중 'likedPosts' 컬렉션 내 해당 포스트 업데이트
async function updateNotificationLikedPosts(userId, postId, postFieldData) {
  const notificationsString = "notifications";
  const notificationId = userId + postId; // notification document id

  const userRef = db.collection(usersString).doc(userId); // get user document reference
  const notificationRef = userRef.collection(notificationsString).doc(notificationId);
  if ((await notificationRef.get()).exists) { // user의 하위 notification collection에 해당 post 존재 O
    try {
      await notificationRef.update(postFieldData); // user document 하위 notifications collection document에 postFieldData 업데이트
      console.log(`success update post :: updateNotificationLikedPosts(), userId: ${userId}, postId: ${postId}`);
    } catch (error) {
      console.error(`error :: updateNotificationLikedPosts(), userId: ${userId}, postId: ${postId}`), error;
    }
  } else { // user의 하위 notifications collection에 해당 post 존재 X
    console.log(`user(userId: ${userId})'s sub collection(${notificationsString}) not exist post(postId: ${postId})`);
  }
}

// # 'drinks' 컬렉션 내 'taggedPosts'에서 해당 포스트 업데이트
async function updateTaggedPostDrinks(postId, postFieldData) {
  const drinksRef = db.collection(drinksString); // get drinks collection reference
  const drinkTags = postFieldData.drinkTags; // user 하위 fieldData중 drinkTags get

  for (const drinkTag of drinkTags) { // drinkTags를 순회
    const drinkId = drinkTag.drinkID; // tag된 drink의 id get
    const drinkRef = drinksRef.doc(drinkId); // get drink document reference
    const taggedPostRef = drinkRef.collection(taggedPostsString).doc(postId); // drink document의 하위 taggedPosts collection의 document reference get

    if ((await taggedPostRef.get()).exists) { // drink의 하위 taggedPosts collection에 해당 post 존재 O
      try {
        await taggedPostRef.update(postFieldData); // drink document의 하위 taggedPosts collection의 document에 postFieldData를 업로드
        console.log(`success update post :: updateTaggedPostDrinks(), drinkId: ${drinkId}, postId: ${postId}`);
      } catch (error) {
        console.error(`error :: updateTaggedPostDrinks(), drinkId: ${drinkId}, postId: ${postId}`, error);
      }
    } else { // drink의 하위 taggedPosts collection에 해당 post 존재 X
      console.log(`drink(drinkId: ${drinkId})'s sub collection(${taggedPostsString}) not exist post(postId: ${postId})`);
    }
  }
}

// post 삭제
// 앱 내에서 호출하는 함수
exports.onPostDelete = functions.https.onCall(async (data, context) => {
  const userId = data.userID; // 매개변수로 받아온 userId
  const postId = data.postID; // 매개변수로 받아온 postId

  // post와 관련된 collection document 삭제
  await deleteDocumentsRelatedToPost(userId, postId);
});

// post와 관련된 document 삭제하는 함수 병렬처리
async function deleteDocumentsRelatedToPost(userId, postId) {
  // 사용자의 'posts' 컬렉션 내 해당 post 삭제
  await deleteUserPost(userId, postId);
  // post 좋아요 누른 모든 user의 'likedPosts'에서 해당 post 삭제
  await deleteOtherUsersLikedPost(postId);
}

// 사용자의 'posts' 컬렉션 내 해당 post 삭제
async function deleteUserPost(userId, postId) {
  const userRef = db.collection(usersString).doc(userId); // get user document reference
  const userPostRef = userRef.collection(postsString).doc(postId); // user의 하위 posts collection의 document reference get
  const userPostSnapshot = await userPostRef.get(); // user의 하위 posts collection의 document snapshot get

  if (userPostSnapshot.exists) { // user의 하위 posts collection에 해당 post 존재 O
    const postFieldData = userPostSnapshot.data(); // user의 하위 field data get
    await deleteTaggedPostsInDrinks(postId, postFieldData); // 'drinks' 컬렉션의 'taggedPosts'에서 해당 post 삭제

    try {
      await userPostRef.delete(); // user의 하위 post document 삭제
      console.log(`success post delete :: deleteUserPost(), userId: ${userId}, postId: ${postId}`);
    } catch (error) {
      console.error(`error :: deleteUserPost(), userId: ${userId}, postId: ${postId}`, error);
    }
  } else { // user의 하위 posts collection에 해당 post 존재 X
    console.log(`user(userId: ${userId})'s sub collection(${postsString}) not exist post(postId: ${postId})`);
  }
}

// posts/<postID> field data drinkTags 돌면서 얻은 drinkID 갖고 drinks/<drinkID>/taggedPosts/<postID> document 삭제
async function deleteTaggedPostsInDrinks(postId, postFieldData) {
  const drinkTags = postFieldData.drinkTags; // post의 하위 field data중 drinkTags get

  drinkTags.forEach(async (drinkTag) => { // drinkTags 순회하며 비동기 클로저 호출
    const drinkId = drinkTag.drinkID; // drinkTag 하위 data중 drinkId get
    const drinkRef = db.collection(drinksString).doc(drinkId); // get drink document reference
    const taggedPostRef = drinkRef.collection(taggedPostsString).doc(postId); // drinks 하위 taggedPosts collection document reference get

    if ((await taggedPostRef.get()).exists) { // drink의 하위 taggedPosts collection에 해당 post 존재 O
      try {
        await taggedPostRef.delete(); // drink 하위 tagged post document 삭제
        console.log(`success taggedPost delete :: deleteTaggedPostsInDrinks(), drinkId: ${drinkId}, likedPostId: ${postId}`);
      } catch (error) {
        console.error(`error :: deleteTaggedPostsInDrinks(), drinkId: ${drinkId}, likedPostId: ${postId}`);
      }
    } else { // drink의 하위 taggedPosts collection에 해당 post 존재 X
      console.log(`drink(drinkId: ${drinkId})'s sub collection(${taggedPostsString}) not exist post(postId: ${postId})`);
    }
  });
}

// post 좋아요 누른 모든 user의 'likedPosts'에서 해당 post 삭제
async function deleteOtherUsersLikedPost(postId) {
  const likedUsersIDRef = db.collection(postsString).doc(postId).collection(likedUsersIDString);
  const likedUsersIDSnapshot = await likedUsersIDRef.get();

  likedUsersIDSnapshot.forEach(async (likedUserIdDoc) =>{
    const userId = likedUserIdDoc.id;

    const userRef = db.collection(usersString).doc(userId);
    const likedPostRef = userRef.collection(likedPostsString).doc(postId);

    if ((await likedPostRef.get()).exists) { // user의 하위 likedPosts collection에 해당 post 존재 X
      try {
        await likedPostRef.delete();
        console.log(`success likedPost delete :: deleteOtherUsersLikedPost(), userId: ${userId}, likedPostId: ${postId}`);
      } catch (error) {
        console.error(`error :: deleteOtherUsersLikedPost(), userId: ${userId}, likedPostId: ${postId}`, error);
      }
    } else { // user의 하위 likedPosts collection에 해당 post 존재 X
      console.log(`user(userId: ${userId})'s sub collection(${likedPostsString}) not exist post(postId: ${postId})`);
    }
  });
}

// 좋아요

// 게시글에 좋아요를 눌렀을 때
exports.onAddLikedToPost = functions.firestore
  .document("posts/{postId}/likedUsersID/{userId}")
  .onCreate(async (snapshot, context) => {
    const postId = context.params.postId;
    const likedUserId = context.params.userId;

    // 좋아요 count 1 증가
    const postRef = db.collection(postsString).doc(postId);
    try {
      await postRef.update({
        "likedCount": fieldValue.increment(1),
      });
    } catch (error) {
      console.error(`error :: likedCount increment(1), postId: ${postId}`, error);
    }

    const postDoc = await postRef.get();
    const postFieldData = postDoc.data();
    // users/<userID>/likedPosts/<postID>에 post upload
    await uploadUserLikedPosts(likedUserId, postId, postFieldData);

    // users/{userId}/notifications{likedUserId + postId}에 post upload
    await uploadUserNotification(likedUserId, postId, postFieldData);
  });

async function uploadUserLikedPosts(likedUserId, postId, postFieldData) {
  const userRef = db.collection(usersString).doc(likedUserId);
  const likedPostRef = userRef.collection(likedPostsString).doc(postId);

  try {
    await likedPostRef.set(postFieldData);
    console.log(`success upload likedPost :: uploadUserLikedPosts(), userId: ${likedUserId}, likedPostId: ${postId}`);
  } catch (error) {
    console.error(`error :: uploadUserLikedPosts(), userId: ${likedUserId}, likedPostId: ${postId}`, error);
  }
}

// users/{userId}/notifications{likedUserId + postId}에 post upload
async function uploadUserNotification(likedUserId, postId, postFieldData) {
  const userId = postFieldData.user.userID;
  if ((userId + postId) == (likedUserId + postId)) {
    console.log(`post writter's userId(${userId}), likedUserId(${likedUserId}) is same id`);
    return;
  }

  const imagesURL = postFieldData.imagesURL;
  const thumbnailImageURL = imagesURL.length == 0 ? "" : imagesURL[0];
  const likedUserRef = db.collection(usersString).doc(likedUserId);
  const likedUserDoc = await likedUserRef.get();
  const likedUserName = likedUserDoc.data().name;
  const likedUser = {
    userID: likedUserId,
    userName: likedUserName,
  };
  const notification = {
    isChecked: false,
    likedTime: timestamp.fromDate(new Date()),
    thumbnailImageURL: thumbnailImageURL,
    likedUser: likedUser,
  };
  const userRef = db.collection(usersString).doc(userId);
  const notificationRef = userRef.collection(notificationsString).doc(likedUserId + postId);
  const notificationsLikedPostRef = notificationRef.collection("likedPost").doc(postId);

  try {
    await notificationRef.set(notification);
    console.log(`success upload notification :: uploadUserNotification(), userId: ${userId}, likedUserId: ${likedUserId}, likedPostId: ${postId}`);
    await notificationsLikedPostRef.set(postFieldData);
    console.log(`success upload notificationLikedPost :: userId: ${userId}, likedUserId: ${likedUserId}, likedPostId: ${postId}`);
  } catch (error) {
    console.error(`error :: uploadUserNotification(), userId: ${userId}, likedUserId: ${likedUserId}, likedPostId: ${postId}`);
  }
}

// 게시글에 좋아요를 취소했을 때
exports.onDeleteLikedToPost = functions.firestore
  .document("posts/{postId}/likedUsersID/{userId}")
  .onDelete(async (snapshot, context) => {
    const postId = context.params.postId;
    const likedUserId = context.params.userId;

    // 좋아요 count 1 감소
    const postRef = db.collection(postsString).doc(postId);
    try {
      await postRef.update({
        "likedCount": fieldValue.increment(-1),
      });
    } catch (error) {
      console.error(`error :: likedCount increment(-1), postId: ${postId}`, error);
    }

    // users/<userID>/likedPosts/<postID>에 post delete
    await deleteUserLikedPost(likedUserId, postId);
    // users/{userId}/notifications{likedUserId + postId}에 post upload
    const postDoc = await postRef.get();
    const postFieldData = postDoc.data();
    const userId = postFieldData.user.userID;
    await deleteUserNotification(userId, likedUserId, postId);
  });

async function deleteUserLikedPost(likedUserId, postId) {
  const likedUserRef = db.collection(usersString).doc(likedUserId);
  const likedPostRef = likedUserRef.collection(likedPostsString).doc(postId);

  try {
    await likedPostRef.delete();
    console.log(`succress delete likedPost :: uploadUserLikedPosts(), userId: ${likedUserId}, likedPostId: ${postId}`);
  } catch (error) {
    console.error(`error :: deleteUserLikedPost(), userId: ${likedUserId}, likedPostId: ${postId}`, error);
  }
}

async function deleteUserNotification(userId, likedUserId, postId) {
  const userRef = db.collection(usersString).doc(userId);
  const notificationRef = userRef.collection(notificationsString).doc(likedUserId + postId);

  try {
    await notificationRef.delete();
    console.log(`success delete notification, userId: ${userId}, likedUserId: ${likedUserId}, postId: ${postId}`);
  } catch (error) {
    console.error(`error :: deleteUserNotification(), userId: ${userId}, likedUserId: ${likedUserId}, postId: ${postId}`);
  }
}

// 술에 좋아요를 눌렀을 때
exports.onAddLikedToDrink = functions.firestore
  .document("drinks/{drinkId}/likedUsersID/{userId}")
  .onCreate(async (snapshot, context) => {
    const drinkId = context.params.drinkId;
    const userId = context.params.userId;

    // users/<userID>/likedDrinks/<drinkID>에 drink upload
    const drinkRef = db.collection(drinksString).doc(drinkId);
    const drinkDoc = await drinkRef.get();
    const drinkFieldData = drinkDoc.data();
    await uploadUserLikedDrinks(userId, drinkId, drinkFieldData);
  });

async function uploadUserLikedDrinks(userId, drinkId, drinkFieldData) {
  const userRef = db.collection(usersString).doc(userId);
  const likedDrinkRef = userRef.collection(likedDrinksString).doc(drinkId);

  try {
    await likedDrinkRef.set(drinkFieldData);
    console.log(`success upload likedDrink :: uploadUserLikedDrinks(), userId: ${userId}, drinkId: ${drinkId}`);
  } catch (error) {
    console.error(`error :: uploadUserLikedDrinks() userId: ${userId}, drinkId: ${drinkId}`, error);
  }
}

// 술에 좋아요를 취소했을 때
exports.onDeleteLikedToDrink = functions.firestore
  .document("drinks/{drinkId}/likedUsersID/{userId}")
  .onDelete(async (snapshot, context) => {
    const drinkId = context.params.drinkId;
    const userId = context.params.userId;

    await deleteUserLikedDrink(userId, drinkId);
  });

async function deleteUserLikedDrink(userId, drinkId) {
  const userRef = db.collection(usersString).doc(userId);
  const likedDrinkRef = userRef.collection(likedDrinksString).doc(drinkId);

  try {
    await likedDrinkRef.delete();
    console.log(`success delete likedDrink :: deleteUserLikedDrink(), userId: ${userId}, drinkId: ${drinkId}`);
  } catch (error) {
    console.error(`error :: deleteUserLikedDrink() userId: ${userId}, drinkId: ${drinkId}`, error);
  }
}

// 술 데이터 업데이트

// drink document field data(rating) 수정됐을 때
exports.onUpdateDrinkRating = functions.firestore
  .document("drinks/{drinkId}")
  .onUpdate(async (snapshot, context) => {
    const drinkId = context.params.drinkId;
    const drinkFieldData = snapshot.after.data();
    const drinkRating = drinkFieldData.rating;

    const likedUsersIdRef = snapshot.after.ref.collection(likedUsersIDString);
    const likedUsersIdSnapshot = await likedUsersIdRef.get();

    for (const likedUsersIdDoc of likedUsersIdSnapshot.docs) {
      const likedUserId = likedUsersIdDoc.id;
      await updateUsersLikedDrinkRating(likedUserId, drinkId, drinkRating);
    }
  });

async function updateUsersLikedDrinkRating(userId, drinkId, rating) {
  const userRef = db.collection(usersString).doc(userId);
  const likedDrinkRef = userRef.collection(likedDrinksString).doc(drinkId);

  if ((await likedDrinkRef.get()).exists) { // user의 하위 likedDrinks collection에 해당 drink 존재 O
    try {
      await likedDrinkRef.update({
        "rating": rating,
      });
      console.log(`success update drink updateUsersLikedDrinkRating(), userId: ${userId}, drinkId: ${drinkId}, rating: ${rating}`);
    } catch (error) {
      console.error(`error :: updateUsersLikedDrinkRating(), userId: ${userId}, drinkId: ${drinkId}, rating: ${rating}`, error);
    }
  } else { // user의 하위 likedDrinks collection에 해당 drink 존재 x
    console.log(`user(userId: ${userId})'s sub collection(${likedDrinksString}) not exist drink(drinkId: ${drinkId})`);

    const drinkRef = db.collection(drinksString).doc(drinkId);
    const drinkSnapshot = await drinkRef.get();
    const drinkFieldData = drinkSnapshot.data();

    try {
      await likedDrinkRef.set(drinkFieldData);
      console.log(`success upload drink :: updateUsersLikedDrinkRating(), userId: ${userId}, drinkId: ${drinkId}`);
    } catch (error) {
      console.error(`error(fail upload drink) :: updateUsersLikedDrinkRating() userId: ${userId}, drinkId: ${drinkId}`, error);
    }
  }
}

// 회원탈퇴
exports.onUserDelete = functions.https.onCall(async (data, context) => {
  const userId = data.userID;
  const userRef = db.collection(usersString).doc(userId);
  if ((await userRef.get()).exists) {
    // user가 작성한 post들 root posts collection에서 삭제
    await deleteUserPosts(userId);
    // user의 likedPosts에 있는 post들 root posts의 post likedCount -1 및 likedUsersID에서 삭제
    await deleteUserLikedPosts(userId);
    // user의 likedDrinks에 있는 drink들 root drinks의 likedUsersID에서 삭제
    await deleteUserLikedDrinks(userId);
  } else {
    console.log(`user(userId: ${userId}) not exists`);
  }
});

// user/posts에 접근하여 postID를 통해 root collection인 posts에서 post delete
async function deleteUserPosts(userId) {
  const userRef = db.collection(usersString).doc(userId);
  const userPostsRef = userRef.collection(postsString);
  const userPostsSnapshot = await userPostsRef.get();

  for (const userPostDoc of userPostsSnapshot.docs) {
    const postId = userPostDoc.id;
    const postRef = db.collection(postsString).doc(postId);
    try {
      await postRef.delete();
      console.log(`success post delete :: deleteUserPosts(), userId: ${userId}, postId: ${postId}`);
    } catch (error) {
      console.error(`error :: deleteUserPosts(), userId: ${userId}, postId: ${postId}`, error);
    }
  }
}

// user/likedPosts에 접근하여 postID를 통해 root collection인 posts에 접근하여 posts/likedUsersID에서 해당 userID를 delete
async function deleteUserLikedPosts(userId) {
  const userRef = db.collection(usersString).doc(userId);
  const userLikedPostsRef = userRef.collection(likedPostsString);
  const userLikedPostsSnapshot = await userLikedPostsRef.get();

  for (const userLikedPostDoc of userLikedPostsSnapshot.docs) {
    const postId = userLikedPostDoc.id;
    const postRef = db.collection(postsString).doc(postId);
    try {
      await postRef.update({
        "likedCount": fieldValue.increment(-1),
      });
      console.log(`success likedCount increment(-1), postId: ${postId}`);
    } catch (error) {
      console.error(`error :: fail likedCount increment(-1), postId: ${postId}`, error);
    }

    const postLikedUserIdRef = postRef.collection(likedUsersIDString).doc(userId);

    try {
      await postLikedUserIdRef.delete();
      console.log(`success likedUserId delete :: deleteUserLikedPosts(), userId: ${userId}, postId: ${postId}`);
    } catch (error) {
      console.error(`error :: deleteUserLikedPosts(), userId: ${userId}, postId: ${postId}`, error);
    }
  }
}

// user/likedDrinks에 접근하여 drinkID를 통해 root collection인 drinks에 접근하여 drinks/likedUsersID에서 해당 userID를 delete
async function deleteUserLikedDrinks(userId) {
  const userRef = db.collection(usersString).doc(userId);
  const userLikedDrinksRef = userRef.collection(likedDrinksString);
  const userLikedDrinksSnapshot = await userLikedDrinksRef.get();

  for (const userLikedDrinkDoc of userLikedDrinksSnapshot.docs) {
    const drinkId = userLikedDrinkDoc.id;
    const drinkRef = db.collection(drinksString).doc(drinkId);
    const drinkLikedUserIdRef = drinkRef.collection(likedUsersIDString).doc(userId);

    try {
      await drinkLikedUserIdRef.delete();
      console.log(`success likedUserId delete :: deleteUserLikedDrinks(), userId: ${userId}, drinkId: ${drinkId}`);
    } catch (error) {
      console.error(`error :: deleteUserLikedDrinks(),userId: ${userId}, drinkId: ${drinkId}`, error);
    }
  }
}
