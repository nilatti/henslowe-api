import PropTypes from 'prop-types';
import React, { Component } from 'react'
import { Glyphicon, Row, Col } from 'react-bootstrap'
import { BrowserRouter as Switch, Router, Route, Link, Redirect } from 'react-router-dom'

import { deleteAct, getAct } from '../../../api/acts'

import ActShow from './ActShow'
import ActForm from './ActForm'

class EditableAct extends Component {
  constructor(props){
    super(props)
    this.state = {
      editFormOpen: false,
      act: null,
    }
  }
  closeForm = () => {
    this.setState({ editFormOpen: false })
  }

  componentDidMount = () => {
      this.loadActFromServer(this.props.match.params.actId)
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.act === null || prevProps.match.params.actId !== this.props.match.params.actId) {
      this.loadActFromServer(this.props.match.params.actId);
    }
  }

  async deleteAct (actId) {
    const response = await deleteAct(actId)
    if (response.status >= 400) {
      this.setState({ errorStatus: 'Error deleting play'})
    } else {
      this.props.history.push('/plays/${this.props.play_id}')
    }
  }

  async loadActFromServer (actId) {
    const response = await getAct(actId)
    if (response.status >= 400) {
      this.setState({ errorStatus: 'Error fetching act' })
    } else {
      this.setState({ act: response.data })
    }
  }

  static getDerivedStateFromProps(props, state) {
    // Store prevId in state so we can compare when props change.
    // Clear out previously-loaded data (so we don't render stale stuff).
    if (props.id !== state.prevId) {
      return {
        act: null,
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

  handleSubmit = (act) => {
    this.props.onFormSubmit(act)
    this.closeForm()
  }

  onDeleteClick = (actId) => {
    this.deleteAct(actId)
  }

  openForm = () => {
    this.setState({ editFormOpen: true })
  }

  render () {

    if (this.state.editFormOpen) {
      return(
        <ActForm
          onFormClose={this.handleFormClose()}
          onFormSubmit={this.handleSubmit()}
        />
      )
    }
    if (this.state.act === null) {
      return (
        <div>Loading!</div>
      )
    }
    return (
      <ActShow
        handleDeleteClick={this.onDeleteClick}
        handleEditClick={this.onEditClick}
      />
    )
  }
}

EditableAct.propTypes = {
  onFormSubmit: PropTypes.func.isRequired
}

export default EditableAct
