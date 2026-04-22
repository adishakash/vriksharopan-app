const multer = require('multer');
const multerS3 = require('multer-s3');
const { S3Client } = require('@aws-sdk/client-s3');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const config = require('../config');

const s3 = new S3Client({
  region: config.aws.region,
  credentials: {
    accessKeyId: config.aws.accessKeyId,
    secretAccessKey: config.aws.secretAccessKey,
  },
});

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_SIZE_BYTES = 5 * 1024 * 1024; // 5 MB

const fileFilter = (req, file, cb) => {
  if (ALLOWED_MIME_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only JPEG, PNG, and WebP images are allowed.'), false);
  }
};

/**
 * Creates a multer-S3 upload middleware scoped to a specific S3 prefix.
 * @param {string} prefix - e.g. 'trees', 'profiles', 'workers'
 */
const createUploader = (prefix) =>
  multer({
    fileFilter,
    limits: { fileSize: MAX_SIZE_BYTES },
    storage: multerS3({
      s3,
      bucket: config.aws.s3Bucket,
      contentType: multerS3.AUTO_CONTENT_TYPE,
      metadata: (req, file, cb) => {
        cb(null, { uploadedBy: req.user ? req.user.sub : 'unknown' });
      },
      key: (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
        const filename = `${prefix}/${uuidv4()}${ext}`;
        cb(null, filename);
      },
      acl: 'public-read',
    }),
  });

const treePhotoUploader = createUploader('trees');
const profilePhotoUploader = createUploader('profiles');

module.exports = { treePhotoUploader, profilePhotoUploader, s3 };
