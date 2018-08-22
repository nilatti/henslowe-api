import PropTypes from 'prop-types';
import React, { Component } from 'react'
import { Glyphicon, Row, Col } from 'react-bootstrap'
import { BrowserRouter as Switch, Router, Route, Link, Redirect } from 'react-router-dom'

import { deletePlay, getPlay } from '../../api/plays'

import PlayShow from './PlayShow'
import PlayForm from './PlayForm'

class EditablePlay extends Component {
  constructor(props){
    super(props)
    this.state = {
      editFormOpen: false,
      play: null,
      toPlaysList: false,
      test: this.props.thisIsATestProp
    }
  }
  closeForm = () => {
    this.setState({ editFormOpen: false })
  }

  componentDidMount = () => {
      this.loadPlayFromServer(this.props.match.params.playId)
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.play === null || prevProps.match.params.playId !== this.props.match.params.playId) {
      this.loadPlayFromServer(this.props.match.params.playId);
    }
  }

  async deletePlay (playId) {
    const response = await deletePlay(playId)
    if (response.status >= 400) {
      this.setState({ errorStatus: 'Error deleting play'})
    } else {
      this.props.history.push('/plays')
    }
  }

  async loadPlayFromServer (playId) {
    const response = await getPlay(playId)
    if (response.status >= 400) {
      this.setState({ errorStatus: 'Error fetching play' })
    } else {
      this.setState({ play: response.data })
    }
  }

  static getDerivedStateFromProps(props, state) {
    // Store prevId in state so we can compare when props change.
    // Clear out previously-loaded data (so we don't render stale stuff).
    if (props.id !== state.prevId) {
      return {
        play: null,
        prevId: props.id,
      };
    }
    // No state update necessary
    return null;
  }

  onEditClick = () => {
    this.openForm()
  }

  handleFormClose = () => {
    this.closeForm()
  }

  handleSubmit = (play) => {
    this.props.onFormSubmit(play)
    this.closeForm()
  }

  onDeleteClick = (playId) => {
    this.deletePlay(playId)
  }

  openForm = () => {
    this.setState({ editFormOpen: true })
  }

  render () {
    if (this.state.toPlaysList === true) {
      return <Redirect to='/plays' />
    }
    if (this.state.editFormOpen) {
      return(
        <PlayForm
          id={this.state.play.id}
          title={this.state.play.title}
          author_id={this.state.play.author.id}
          genre={this.state.play.genre}
          acts={this.state.play.acts}
          onFormClose={this.handleFormClose()}
          onFormSubmit={this.handleSubmit()}
        />
      )
    }
    if (this.state.play === null) {
      return (
        <div>Loading!</div>
      )
    }
    return (
      <PlayShow
        author={`${this.state.play.author.first_name} ${this.state.play.author.last_name}`}
        id={this.state.play.id}
        handleDeleteClick={this.onDeleteClick}
        handleEditClick={this.onEditClick}
        title={this.state.play.title}
        acts={this.state.play.acts}
      />
    )
  }
}

EditablePlay.propTypes = {
  onFormSubmit: PropTypes.func.isRequired
}

export default EditablePlay
