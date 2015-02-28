express = require('express')
router = express.Router()
pool = require('./dbpool').pool

router.use '/newList', (req, res, next)-> res.send 'ok'

router.use '/saveList', (req,res,next)-> res.send 'ok'

router.use '/deleteList', (req,res,next)-> res.send 'ok'

router.use '/newPerson', (req,res,next)-> res.send 'ok'

router.use '/savePerson', (req,res,next)-> res.send 'ok'

router.use '/deletePerson', (req,res,next)-> res.send 'ok'

router.use '/addPerson', (req,res,next)-> res.send 'ok'

router.use '/removePerson', (req,res,next)-> res.send 'ok'



module.exports = router
